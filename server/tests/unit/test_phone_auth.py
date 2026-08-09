from datetime import UTC, datetime, timedelta

import pytest

from kitchen_server.auth.phone import (
    InMemoryOtpChallengeStore,
    InMemoryRiskPreflight,
    OtpService,
    RecordingSmsSender,
    RiskContext,
    mask_cn_mobile,
    normalize_cn_mobile,
    phone_subject,
)
from kitchen_server.auth.service import AuthError


def test_normalize_only_accepts_cn_mobile_numbers() -> None:
    assert normalize_cn_mobile("138 0013 8000") == "+8613800138000"
    assert normalize_cn_mobile("+86 13800138000") == "+8613800138000"
    assert mask_cn_mobile("+8613800138000") == "+86****8000"
    with pytest.raises(AuthError, match="phone_invalid"):
        normalize_cn_mobile("+85213800138000")
    with pytest.raises(AuthError, match="phone_invalid"):
        normalize_cn_mobile("01012345678")


@pytest.mark.asyncio
async def test_otp_is_hmac_only_single_use_and_attempt_limited() -> None:
    now = datetime(2026, 8, 9, tzinfo=UTC)
    service = OtpService(
        InMemoryOtpChallengeStore(), pepper="test-pepper", max_attempts=2, ttl_seconds=60
    )
    challenge, code = await service.issue("13800138000", now=now)

    with pytest.raises(AuthError, match="otp_invalid"):
        await service.verify(challenge.challenge_id, "000000", now=now)
    with pytest.raises(AuthError, match="otp_invalid"):
        await service.verify(challenge.challenge_id, "000000", now=now)
    with pytest.raises(AuthError, match="otp_invalid"):
        await service.verify(challenge.challenge_id, code, now=now)


@pytest.mark.asyncio
async def test_otp_success_is_single_use_and_expiry_is_enforced() -> None:
    now = datetime(2026, 8, 9, tzinfo=UTC)
    service = OtpService(InMemoryOtpChallengeStore(), pepper="test-pepper")
    challenge, code = await service.issue("13800138000", now=now)

    used = await service.verify(challenge.challenge_id, code, now=now)
    assert used.status == "used"
    with pytest.raises(AuthError, match="otp_invalid"):
        await service.verify(challenge.challenge_id, code, now=now)

    expired, expired_code = await service.issue("13900139000", now=now)
    with pytest.raises(AuthError, match="otp_invalid"):
        await service.verify(
            expired.challenge_id,
            expired_code,
            now=now + timedelta(minutes=6),
        )

    old, old_code = await service.issue("13800138000", now=now)
    await service.issue("13800138000", now=now)
    with pytest.raises(AuthError, match="otp_invalid"):
        await service.verify(old.challenge_id, old_code, now=now)


@pytest.mark.asyncio
async def test_preflight_blocks_before_sms_sender() -> None:
    gate = InMemoryRiskPreflight(max_total=1)
    sender = RecordingSmsSender()
    context = RiskContext("install-1", "192.0.2.1", "192.0.2.0/24", "sms_send")
    await gate.reserve(phone_subject("+8613800138000", "pepper"), context)
    with pytest.raises(AuthError, match="sms_rate_limited"):
        await gate.reserve(phone_subject("+8613900139000", "pepper"), context)
    assert sender.calls == []


@pytest.mark.asyncio
async def test_preflight_covers_ip_and_network_dimensions() -> None:
    gate = InMemoryRiskPreflight(max_total=10, max_per_dimension=1)
    context = RiskContext("install-1", "192.0.2.1", "192.0.2.0/24", "sms_send")
    await gate.reserve("subject-1", context)
    with pytest.raises(AuthError, match="sms_rate_limited"):
        await gate.reserve(
            "subject-2",
            RiskContext("install-2", "192.0.2.1", "192.0.2.0/24", "sms_send"),
        )
