"""
Tests for django management commands
"""

from unittest.mock import patch
from psycopg2 import OperationalError as Psycopg2OpError
from django.core.management import call_command
from django.db import OperationalError
from django.test import SimpleTestCase


# 모킹하고자 하는 함수를 명시
@patch('core.management.commands.wait_for_db.Command.check')
class CommandTests(SimpleTestCase):
    """Test commands"""

    # check 함수가 호출되는지 확인
    def test_wait_for_db_ready(self, patched_check):
        """test waiting for db if db ready"""
        # MOCK 객체가 호출될때 반환할 값을 True로 설정 (false여도 통과한다. 예외발생을 안시켰기때문)
        patched_check.return_value = True
        # 관리명령어 호출 (이때 patched_check가 호출됨(True 반환))
        call_command('wait_for_db')

        # 한번 호출되었는지, 인자가 맞는지 확인
        patched_check.assert_called_once_with(databases=['default'])

    # db 연결이 실패하다가 성공하는 경우
    @patch('time.sleep')
    def test_wait_for_db_delay(self, patched_sleep, patched_check):
        """Test waiting for db when getting OperationalError"""
        patched_check.side_effect = [Psycopg2OpError] * 4 \
            + [OperationalError] * 3 + [True] \

        call_command('wait_for_db')

        self.assertEqual(patched_check.call_count, 8)
        patched_check.assert_called_with(databases=['default'])
