import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:kitchen_import_domain/kitchen_import_domain.dart';

/// 只读取公开 HTTPS HTML，并将常见网页元数据降级为可结构化文本。
///
/// 安全校验与内容提取放在同一适配器边界：每次重定向都重新检查目标地址，
/// 避免公开域名把请求引向本机或私网。输出仍是文本，不直接构造领域草稿。
class SafePublicContentExtractor implements PublicContentExtractor {
  const SafePublicContentExtractor();

  static const _maximumBytes = 2 * 1024 * 1024;

  @override
  Future<String> extract(Uri url) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final response = await _openFollowingSafeRedirects(client, url);
      final contentType = response.headers.contentType;
      if (contentType?.mimeType != 'text/html') {
        throw const ImportPipelineException('nonHtml', '该链接不是可读取的网页内容。');
      }
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
        if (bytes.length > _maximumBytes) {
          throw const ImportPipelineException(
            'contentTooLarge',
            '网页内容超过 2 MB，请改为粘贴正文。',
          );
        }
      }
      final html = utf8.decode(bytes, allowMalformed: true);
      return extractRecipeTextFromHtml(html);
    } on ImportPipelineException {
      rethrow;
    } on TimeoutException {
      throw const ImportPipelineException(
        'timeout',
        '链接读取超时，原始网址已保留，可以重试或粘贴正文。',
      );
    } on SocketException {
      throw const ImportPipelineException(
        'unreachable',
        '当前无法访问链接，原始网址已保留，可以稍后重试。',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<HttpClientResponse> _openFollowingSafeRedirects(
    HttpClient client,
    Uri initialUrl,
  ) async {
    var current = initialUrl;
    for (var redirectCount = 0; redirectCount <= 3; redirectCount++) {
      await _validatePublicHttps(current);
      final request = await client.getUrl(current);
      request.followRedirects = false;
      request.headers.set(HttpHeaders.acceptHeader, 'text/html');
      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      if (!response.isRedirect) return response;
      final location = response.headers.value(HttpHeaders.locationHeader);
      await response.drain<void>();
      if (location == null || redirectCount == 3) {
        throw const ImportPipelineException(
          'tooManyRedirects',
          '链接重定向次数过多，请改为粘贴正文。',
        );
      }
      current = current.resolve(location);
    }
    throw const ImportPipelineException(
      'tooManyRedirects',
      '链接重定向次数过多，请改为粘贴正文。',
    );
  }

  Future<void> _validatePublicHttps(Uri url) async {
    if (url.scheme != 'https' || url.host.isEmpty) {
      throw const ImportPipelineException(
        'unsupportedUrl',
        '只支持无需登录的公开 HTTPS 链接。',
      );
    }
    final addresses = await InternetAddress.lookup(url.host);
    if (addresses.isEmpty || addresses.any(_isPrivateAddress)) {
      throw const ImportPipelineException('unsafeUrl', '该地址指向本机或私有网络，无法导入。');
    }
  }

  bool _isPrivateAddress(InternetAddress address) {
    if (address.isLoopback || address.isLinkLocal) return true;
    final raw = address.rawAddress;
    if (address.type == InternetAddressType.IPv4) {
      return raw[0] == 10 ||
          raw[0] == 127 ||
          (raw[0] == 169 && raw[1] == 254) ||
          (raw[0] == 172 && raw[1] >= 16 && raw[1] <= 31) ||
          (raw[0] == 192 && raw[1] == 168);
    }
    return raw.isNotEmpty && (raw[0] & 0xfe) == 0xfc;
  }

  String extractRecipeTextFromHtml(String html) {
    // 优先选择语义最明确的标准数据；只有站点未提供结构化元数据时，
    // 才逐步降级到 Open Graph 和页面正文，减少导航与推荐内容混入菜谱。
    final recipe = _recipeJsonLd(html);
    if (recipe != null) return recipe;
    final article = _articleJsonLd(html);
    if (article != null) return article;
    final openGraph = _openGraphArticle(html);
    if (openGraph != null) return openGraph;
    final title = RegExp(
      r'<title[^>]*>([\s\S]*?)</title>',
      caseSensitive: false,
    ).firstMatch(html)?.group(1);
    final main = RegExp(
      r'<(?:article|main)[^>]*>([\s\S]*?)</(?:article|main)>',
      caseSensitive: false,
    ).firstMatch(html)?.group(1);
    return [
      if (title != null) _plainText(title),
      _plainText(main ?? html),
    ].where((part) => part.isNotEmpty).join('\n');
  }

  String? _recipeJsonLd(String html) {
    final scripts = RegExp(
      r"""<script[^>]+type=["']application/ld\+json["'][^>]*>([\s\S]*?)</script>""",
      caseSensitive: false,
    ).allMatches(html);
    for (final script in scripts) {
      try {
        final decoded = jsonDecode(script.group(1)!);
        final recipe = _findRecipe(decoded);
        if (recipe == null) continue;
        final ingredients = (recipe['recipeIngredient'] as List<dynamic>? ?? [])
            .whereType<String>();
        final steps = _instructionLines(recipe['recipeInstructions']);
        return [
              recipe['name'],
              recipe['description'],
              if (ingredients.isNotEmpty) '食材：',
              ...ingredients,
              if (steps.isNotEmpty) '步骤：',
              ...steps.indexed.map((item) => '${item.$1 + 1}. ${item.$2}'),
            ]
            .whereType<String>()
            .where((line) => line.trim().isNotEmpty)
            .join('\n');
      } on FormatException {
        continue;
      }
    }
    return null;
  }

  String? _openGraphArticle(String html) {
    String? title;
    String? description;
    final tags = RegExp(
      r'<meta\b[^>]*>',
      caseSensitive: false,
    ).allMatches(html);
    for (final tagMatch in tags) {
      final attributes = <String, String>{};
      for (final attribute in RegExp(
        r'''([:\w-]+)\s*=\s*(["'])([\s\S]*?)\2''',
        caseSensitive: false,
      ).allMatches(tagMatch.group(0)!)) {
        attributes[attribute.group(1)!.toLowerCase()] = attribute.group(3)!;
      }
      final key = (attributes['property'] ?? attributes['name'])?.toLowerCase();
      final content = attributes['content'];
      if (content == null) continue;
      if (key == 'og:title') title = _decodeHtmlText(content);
      if (key == 'og:description') description = _decodeHtmlText(content);
    }
    if (description == null || description.trim().isEmpty) return null;
    return [
      if (title != null && title.trim().isNotEmpty) _normalizePageTitle(title),
      _normalizeArticleDescription(description),
    ].join('\n');
  }

  String? _articleJsonLd(String html) {
    final scripts = RegExp(
      r"""<script[^>]+type=["']application/ld\+json["'][^>]*>([\s\S]*?)</script>""",
      caseSensitive: false,
    ).allMatches(html);
    for (final script in scripts) {
      try {
        final article = _findStructuredType(
          jsonDecode(script.group(1)!),
          'Article',
        );
        if (article == null) continue;
        final headline = article['headline'] as String?;
        final description = article['description'] as String?;
        final text =
            [
                  if (headline != null) _normalizePageTitle(headline),
                  if (description != null)
                    _normalizeArticleDescription(description),
                ]
                .whereType<String>()
                .where((line) => line.trim().isNotEmpty)
                .join('\n');
        if (text.isNotEmpty) return text;
      } on FormatException {
        continue;
      }
    }
    return null;
  }

  String _normalizeArticleDescription(String value) {
    return _decodeHtmlText(value)
        .replaceAllMapped(
          RegExp(
            r'\s*(?:🍳\s*)?((?:食材|用料|材料|配料)(?:清单)?)(?=\s*(?:[:：]|&|＆|和|及|/|$))\s*(?:(?:&|＆|和|及|/)\s*(?:做法|步骤|流程))?\s*[:：]?\s*',
            caseSensitive: false,
          ),
          (match) => '\n${match.group(1)}：\n',
        )
        .replaceAllMapped(
          RegExp(r'\s*([0-9])\uFE0F?\u20E3\s*'),
          (match) => '\n${match.group(1)}. ',
        )
        .replaceAllMapped(
          RegExp(r'\s*(步骤|流程|做法|制作方法|烹饪步骤|操作步骤)\s*[:：]\s*'),
          (match) => '\n${match.group(1)}：\n',
        )
        .replaceAllMapped(
          RegExp(r'\s+(?=(?:\d+|[一二三四五六七八九十]+)[.、:：)]\s*)'),
          (_) => '\n',
        )
        .replaceAllMapped(RegExp(r'\s*[,，;；]\s*(?=\d+[.、:：)]\s*)'), (_) => '\n')
        // 部分 Article 元数据会把食材换行压成空格；数量结尾是目前唯一足够
        // 稳定的通用边界，无数量食材仍保留给用户确认，避免过度猜测。
        .replaceAllMapped(
          RegExp(
            r'((?:\d+(?:\.\d+)?\s*(?:克|g|kg|毫升|ml|个|只|勺|片|杯)|适量|少许))\s+',
            caseSensitive: false,
          ),
          (match) => '${match.group(1)}\n',
        )
        .replaceAll(RegExp(r'\s*[｜|]\s*'), '\n')
        .replaceAllMapped(
          RegExp(r'\s+(?=(?:酱汁|料汁|调味汁|腌料)\s*[:：])'),
          (_) => '\n',
        )
        .replaceAllMapped(
          RegExp(
            r'\s*(?:⚠️?\s*)?(tips?|小贴士|注意事项)\s*[:：]?\s*',
            caseSensitive: false,
          ),
          (_) => '\n注意事项：\n',
        )
        .trim();
  }

  String _normalizePageTitle(String value) {
    return _decodeHtmlText(
      value,
    ).replaceFirst(RegExp(r'\s+[-–—]\s+[^-–—]{1,20}$'), '').trim();
  }

  String _decodeHtmlText(String value) {
    return value
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&');
  }

  Map<String, dynamic>? _findStructuredType(Object? value, String targetType) {
    if (value is List) {
      for (final item in value) {
        final found = _findStructuredType(item, targetType);
        if (found != null) return found;
      }
    } else if (value is Map<String, dynamic>) {
      final type = value['@type'];
      if (type == targetType || (type is List && type.contains(targetType))) {
        return value;
      }
      for (final child in value.values) {
        final found = _findStructuredType(child, targetType);
        if (found != null) return found;
      }
    }
    return null;
  }

  Map<String, dynamic>? _findRecipe(Object? value) {
    if (value is List) {
      for (final item in value) {
        final found = _findRecipe(item);
        if (found != null) return found;
      }
    } else if (value is Map<String, dynamic>) {
      final type = value['@type'];
      if (type == 'Recipe' || (type is List && type.contains('Recipe'))) {
        return value;
      }
      for (final child in value.values) {
        final found = _findRecipe(child);
        if (found != null) return found;
      }
    }
    return null;
  }

  List<String> _instructionLines(Object? value) {
    if (value is String) return _splitInstructionText(value);
    if (value is List) {
      return value
          .expand(_instructionLines)
          .where((line) => line.trim().isNotEmpty)
          .toList(growable: false);
    }
    if (value is Map<String, dynamic>) {
      // HowToSection 常把步骤放在 itemListElement 中；应优先展开子项，
      // 不能把分区名称误当成一道步骤。
      final nested = value['itemListElement'] ?? value['steps'];
      if (nested != null) return _instructionLines(nested);
      final text = value['text'] as String? ?? value['name'] as String?;
      return text == null ? const [] : _splitInstructionText(text);
    }
    return const [];
  }

  List<String> _splitInstructionText(String value) {
    final text = value.trim();
    if (text.isEmpty) return const [];
    // 某些站点把全部步骤压在一个字符串中，例如：
    // “0.焯水,1.翻炒,2.收汁”。编号只用于识别边界，最终步骤顺序由
    // 列表位置表达，因此即使来源从 0 开始，也不会把 0 带入编辑器。
    final markers = RegExp(
      r'(?:^|[,，;；])\s*\d+[.、:：)]\s*',
    ).allMatches(text).toList(growable: false);
    if (markers.isEmpty || markers.first.start != 0) return [text];

    final lines = <String>[];
    for (var index = 0; index < markers.length; index++) {
      final start = markers[index].end;
      final end = index + 1 < markers.length
          ? markers[index + 1].start
          : text.length;
      final line = text.substring(start, end).trim();
      if (line.isNotEmpty) lines.add(line);
    }
    return lines;
  }

  String _plainText(String html) {
    return _decodeHtmlText(
          html
              .replaceAll(
                RegExp(r'<script[\s\S]*?</script>', caseSensitive: false),
                '',
              )
              .replaceAll(
                RegExp(r'<style[\s\S]*?</style>', caseSensitive: false),
                '',
              )
              .replaceAll(RegExp(r'<[^>]+>'), '\n'),
        )
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .take(500)
        .join('\n');
  }
}
