"""Create runtime metadata used by the readiness probe."""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "20260803_0001"
down_revision: str | Sequence[str] | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    runtime_metadata = op.create_table(
        "runtime_metadata",
        sa.Column("id", sa.SmallInteger(), nullable=False),
        sa.Column("schema_version", sa.Integer(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.CheckConstraint("id = 1", name="ck_runtime_metadata_singleton"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.bulk_insert(runtime_metadata, [{"id": 1, "schema_version": 1}])


def downgrade() -> None:
    op.drop_table("runtime_metadata")
