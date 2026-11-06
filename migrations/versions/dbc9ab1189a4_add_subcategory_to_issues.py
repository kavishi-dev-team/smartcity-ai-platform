"""add subcategory to issues

Revision ID: dbc9ab1189a4
Revises: 838ec231d5e8
Create Date: 2026-11-03
"""

from alembic import op
import sqlalchemy as sa


revision = "dbc9ab1189a4"
down_revision = "838ec231d5e8"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        "issues",
        sa.Column("subcategory", sa.String(length=100), nullable=True)
    )
    op.create_index(
        op.f("ix_issues_subcategory"),
        "issues",
        ["subcategory"],
        unique=False
    )


def downgrade():
    op.drop_index(
        op.f("ix_issues_subcategory"),
        table_name="issues"
    )
    op.drop_column("issues", "subcategory")