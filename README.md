import pytest
from unittest.mock import MagicMock, patch
from sqlalchemy.exc import SQLAlchemyError

from your_module.address_repository import AddressRepository
from your_module.exceptions import DatabaseException
from your_module.models.address import Address


class TestAddressRepository:

    def test_save_address_info_success_when_address_id_is_none(self):
        session = MagicMock()
        repo = AddressRepository(session)

        address = MagicMock(spec=Address)
        address.address_id = None

        result = repo.save_address_info(address)

        session.add.assert_called_once_with(address)
        session.flush.assert_called_once()
        assert result == address

    def test_save_address_info_success_when_address_id_exists(self):
        session = MagicMock()
        repo = AddressRepository(session)

        address = MagicMock(spec=Address)
        address.address_id = 101

        result = repo.save_address_info(address)

        session.add.assert_not_called()
        session.flush.assert_not_called()
        assert result == address

    def test_save_address_info_raises_database_exception_on_sqlalchemy_error(self):
        session = MagicMock()
        repo = AddressRepository(session)

        address = MagicMock(spec=Address)
        address.address_id = None

        session.add.side_effect = SQLAlchemyError("db failure")

        with pytest.raises(DatabaseException) as exc_info:
            repo.save_address_info(address)

        assert "Error saving Address details" in str(exc_info.value)
        session.add.assert_called_once_with(address)

    def test_get_address_info_by_address_id_success_found(self):
        session = MagicMock()
        repo = AddressRepository(session)

        address = MagicMock(spec=Address)
        session.query.return_value.get.return_value = address

        result = repo.get_address_info_by_address_id(1)

        session.query.assert_called_once_with(Address)
        session.query.return_value.get.assert_called_once_with(1)
        assert result == address

    def test_get_address_info_by_address_id_returns_none_when_not_found(self):
        session = MagicMock()
        repo = AddressRepository(session)

        session.query.return_value.get.return_value = None

        result = repo.get_address_info_by_address_id(1)

        session.query.assert_called_once_with(Address)
        session.query.return_value.get.assert_called_once_with(1)
        assert result is None

    def test_get_address_info_by_address_id_raises_database_exception_on_error(self):
        session = MagicMock()
        repo = AddressRepository(session)

        session.query.side_effect = Exception("unexpected failure")

        with pytest.raises(DatabaseException) as exc_info:
            repo.get_address_info_by_address_id(1)

        assert "Unable to get Address Info" in str(exc_info.value)

    def test_update_address_updates_existing_address(self):
        session = MagicMock()
        repo = AddressRepository(session)

        existing_address = MagicMock(spec=Address)
        session.query.return_value.get.return_value = existing_address

        address_info = {"address_id": 10, "city": "Fairfax", "state": "VA"}

        result = repo.update_address(address_info)

        session.query.assert_called_once_with(Address)
        session.query.return_value.get.assert_called_once_with(10)
        existing_address.set_address.assert_called_once_with(address_info)
        session.flush.assert_called_once()
        assert result == existing_address

    @patch("your_module.address_repository.Address.from_dict")
    def test_update_address_creates_new_address_when_address_id_not_present(self, mock_from_dict):
        session = MagicMock()
        repo = AddressRepository(session)

        new_address = MagicMock(spec=Address)
        mock_from_dict.return_value = new_address
        repo.save_address_info = MagicMock(return_value=new_address)

        address_info = {"city": "Fairfax", "state": "VA"}

        result = repo.update_address(address_info)

        mock_from_dict.assert_called_once_with(address_info)
        repo.save_address_info.assert_called_once_with(new_address)
        session.flush.assert_called_once()
        assert result == new_address

    @patch("your_module.address_repository.Address.from_dict")
    def test_update_address_creates_new_address_when_address_id_is_none(self, mock_from_dict):
        session = MagicMock()
        repo = AddressRepository(session)

        new_address = MagicMock(spec=Address)
        mock_from_dict.return_value = new_address
        repo.save_address_info = MagicMock(return_value=new_address)

        address_info = {"address_id": None, "city": "Fairfax"}

        result = repo.update_address(address_info)

        mock_from_dict.assert_called_once_with(address_info)
        repo.save_address_info.assert_called_once_with(new_address)
        session.flush.assert_called_once()
        assert result == new_address

    def test_update_address_raises_database_exception_on_sqlalchemy_error(self):
        session = MagicMock()
        repo = AddressRepository(session)

        session.query.side_effect = SQLAlchemyError("update failed")

        with pytest.raises(DatabaseException) as exc_info:
            repo.update_address({"address_id": 20, "city": "Reston"})

        assert "Error adding address details" in str(exc_info.value)
