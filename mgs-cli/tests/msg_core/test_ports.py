import pytest
from mgs.mgs.mgs_core.ports import validate_ports, split_ports

def test_validate_ports_valid():
    assert validate_ports("8080:9090") is True

def test_validate_ports_invalid_format():
    assert validate_ports("invalid_format") is False

def test_validate_ports_invalid_range():
    assert validate_ports("8080:70000") is False

def test_split_ports_valid():
    result = split_ports("8080:9090")
    assert result == (8080, 9090)

def test_split_ports_invalid_format():
    with pytest.raises(ValueError, match="Invalid ports format"):
        split_ports("invalid_format")

def test_split_ports_invalid_range():
    with pytest.raises(ValueError, match="Invalid ports. Port numbers should be between 1 and 65535."):
        split_ports("8080:70000")