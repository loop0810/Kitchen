from __future__ import annotations

import asyncio
import json
from datetime import UTC, datetime, timedelta

import jwt
import pytest
from cryptography.hazmat.primitives.asymmetric import rsa

from kitchen_server.auth.apple import (
    AppleCredential,
    AppleIdentityVerifier,
    AppleVerifierConfig,
)
from kitchen_server.auth.service import AuthError


class _Keys:
    def __init__(self, key_id: str, jwk: dict[str, object]) -> None:
        self.key_id = key_id
        self.jwk = jwk
        self.refreshes = 0

    async def keys(self, *, force_refresh: bool = False) -> dict[str, dict[str, object]]:
        if force_refresh:
            self.refreshes += 1
        return {self.key_id: self.jwk}


class _FlowState:
    def __init__(self) -> None:
        self.consumed: set[tuple[str, str]] = set()

    async def issue(self, flow_id: str, nonce: str, *, now: datetime | None = None) -> None:
        return

    async def consume(self, flow_id: str, nonce: str) -> bool:
        value = (flow_id, nonce)
        if value in self.consumed:
            return False
        self.consumed.add(value)
        return flow_id == "flow-1" and nonce == "nonce-1"


def _fixture() -> tuple[AppleIdentityVerifier, rsa.RSAPrivateKey]:
    private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    public_jwk = json.loads(jwt.algorithms.RSAAlgorithm.to_jwk(private_key.public_key()))
    key_provider = _Keys("key-1", public_jwk)
    state_store = _FlowState()
    verifier = AppleIdentityVerifier(
        AppleVerifierConfig(client_id="com.loop.kitchenNotes"),
        key_provider,
        state_store,
    )
    return verifier, private_key


def _credential(private_key: rsa.RSAPrivateKey, **overrides: object) -> AppleCredential:
    now = datetime.now(UTC)
    claims: dict[str, object] = {
        "iss": "https://appleid.apple.com",
        "aud": "com.loop.kitchenNotes",
        "sub": "apple-subject-1",
        "nonce": "nonce-1",
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(minutes=5)).timestamp()),
    }
    claims.update(overrides)
    token = jwt.encode(claims, private_key, algorithm="RS256", headers={"kid": "key-1"})
    return AppleCredential(
        identity_token=token,
        authorization_code="authorization-code",
        flow_id="flow-1",
        nonce="nonce-1",
        email="relay@example.com",
        given_name="Apple",
        family_name="User",
    )


def test_valid_apple_identity_maps_only_verified_subject_and_optional_profile() -> None:
    verifier, private_key = _fixture()

    result = asyncio.run(verifier.verify(_credential(private_key)))

    assert result.provider == "apple"
    assert result.provider_subject == "apple-subject-1"
    assert result.email == "relay@example.com"
    assert result.issuer_audience_scope.endswith(":com.loop.kitchenNotes")


@pytest.mark.parametrize(
    ("claim", "value"),
    [
        ("aud", "wrong-client"),
        ("iss", "https://attacker.example"),
        ("nonce", "wrong-nonce"),
        ("exp", int((datetime.now(UTC) - timedelta(minutes=5)).timestamp())),
    ],
)
def test_apple_claim_mismatch_is_rejected(claim: str, value: object) -> None:
    verifier, private_key = _fixture()
    credential = _credential(private_key, **{claim: value})
    if claim == "nonce":
        credential = AppleCredential(
            identity_token=credential.identity_token,
            authorization_code=credential.authorization_code,
            flow_id=credential.flow_id,
            nonce="nonce-1",
        )

    with pytest.raises(AuthError, match="invalid_credentials"):
        asyncio.run(verifier.verify(credential))


def test_apple_flow_state_is_one_time() -> None:
    verifier, private_key = _fixture()
    credential = _credential(private_key)

    asyncio.run(verifier.verify(credential))
    with pytest.raises(AuthError, match="invalid_credentials"):
        asyncio.run(verifier.verify(credential))
