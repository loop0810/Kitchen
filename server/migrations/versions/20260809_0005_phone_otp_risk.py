"""Add phone OTP challenges, send intents and redacted security events."""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "20260809_0005"
down_revision: str | Sequence[str] | None = "20260809_0003"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "otp_challenges",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("phone_subject", sa.String(length=64), nullable=False),
        sa.Column("otp_digest", sa.String(length=128), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("attempts", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("used_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_otp_challenge_phone_status", "otp_challenges", ["phone_subject", "status"])
    op.create_table(
        "sms_send_intents",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("challenge_id", sa.String(length=36), nullable=False),
        sa.Column("phone_subject", sa.String(length=64), nullable=False),
        sa.Column("cost_units", sa.Integer(), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("settled_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["challenge_id"], ["otp_challenges.id"], ondelete="CASCADE"),
    )
    op.create_index("ix_sms_intent_status_created", "sms_send_intents", ["status", "created_at"])
    op.create_table(
        "auth_security_events",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("event", sa.String(length=80), nullable=False),
        sa.Column("rule", sa.String(length=80), nullable=True),
        sa.Column("phone_masked", sa.String(length=32), nullable=True),
        sa.Column("related_id", sa.String(length=128), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_auth_security_event_created", "auth_security_events", ["created_at"])


def downgrade() -> None:
    op.drop_index("ix_auth_security_event_created", table_name="auth_security_events")
    op.drop_table("auth_security_events")
    op.drop_index("ix_sms_intent_status_created", table_name="sms_send_intents")
    op.drop_table("sms_send_intents")
    op.drop_index("ix_otp_challenge_phone_status", table_name="otp_challenges")
    op.drop_table("otp_challenges")
