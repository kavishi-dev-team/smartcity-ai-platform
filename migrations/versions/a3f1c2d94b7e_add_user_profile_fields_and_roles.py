"""add user profile fields and uppercase roles

Revision ID: a3f1c2d94b7e
Revises: 838ec231d5e8
Create Date: 2026-10-20 10:00:00.000000
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'a3f1c2d94b7e'
down_revision: Union[str, None] = '838ec231d5e8'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('users', sa.Column('phone_number', sa.String(length=20), nullable=True))
    op.add_column('users', sa.Column('address', sa.String(length=500), nullable=True))
    op.add_column('users', sa.Column('profile_photo_url', sa.String(length=500), nullable=True))
    op.add_column(
        'users',
        sa.Column('is_email_verified', sa.Boolean(), server_default=sa.false(), nullable=False),
    )
    op.add_column(
        'users',
        sa.Column(
            'updated_at',
            sa.DateTime(timezone=True),
            server_default=sa.text('now()'),
            nullable=False,
        ),
    )
    # Earlier default was lowercase 'citizen'; roles are now SUPER_ADMIN,
    # CITY_MANAGER, DEPARTMENT_OFFICER, CITIZEN.
    op.execute("UPDATE users SET role = UPPER(role)")


def downgrade() -> None:
    op.drop_column('users', 'updated_at')
    op.drop_column('users', 'is_email_verified')
    op.drop_column('users', 'profile_photo_url')
    op.drop_column('users', 'address')
    op.drop_column('users', 'phone_number')