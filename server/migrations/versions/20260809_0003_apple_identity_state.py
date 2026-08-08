"""Add Apple identity profile and revocation state."""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "20260809_0003"
down_revision: str | Sequence[str] | None = "20260808_0002"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "auth_identities",
        sa.Column("status", sa.String(length=32), nullable=False, server_default="active"),
    )
    op.add_column("auth_identities", sa.Column("email", sa.String(length=320), nullable=True))
    op.add_column("auth_identities", sa.Column("given_name", sa.String(length=120), nullable=True))
    op.add_column("auth_identities", sa.Column("family_name", sa.String(length=120), nullable=True))
    op.add_column(
        "auth_identities", sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True)
    )
    op.create_check_constraint(
        "ck_auth_identity_status",
        "auth_identities",
        "status IN ('active', 'revoked')",
    )
    op.alter_column("auth_identities", "status", server_default=None)


def downgrade() -> None:
    op.drop_constraint("ck_auth_identity_status", "auth_identities", type_="check")
    op.drop_column("auth_identities", "revoked_at")
    op.drop_column("auth_identities", "family_name")
    op.drop_column("auth_identities", "given_name")
    op.drop_column("auth_identities", "email")
    op.drop_column("auth_identities", "status")
