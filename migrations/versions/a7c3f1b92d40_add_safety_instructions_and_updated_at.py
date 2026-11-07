"""add safety_instructions and updated_at to safety_alerts

Revision ID: a7c3f1b92d40
Revises: 838ec231d5e8
Create Date: 2026-10-21 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a7c3f1b92d40'
down_revision: Union[str, None] = '838ec231d5e8'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        'safety_alerts',
        sa.Column('safety_instructions', sa.Text(), nullable=True),
    )
    op.add_column(
        'safety_alerts',
        sa.Column(
            'updated_at',
            sa.DateTime(timezone=True),
            server_default=sa.text('now()'),
            nullable=False,
        ),
    )


def downgrade() -> None:
    op.drop_column('safety_alerts', 'updated_at')
    op.drop_column('safety_alerts', 'safety_instructions')
