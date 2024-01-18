import pytest
from mgs.mgs_core.realm import split_realm

def test_split_realm_no_dash():
    realm = "example"
    prefix, suffix = split_realm(realm)
    assert prefix == realm
    assert suffix == ""

def test_split_realm_with_dash():
    realm = "example-realm_123"
    prefix, suffix = split_realm(realm)
    assert prefix == "example-realm"
    assert suffix == "123"

def test_split_realm_dash_at_start():
    realm = "-start-with-dash"
    prefix, suffix = split_realm(realm)
    assert prefix == ""
    assert suffix == "start-with-dash"

def test_split_realm_multiple_dashes():
    realm = "one-two-three"
    prefix, suffix = split_realm(realm)
    assert prefix == "one-two"
    assert suffix == "three"

import pytest
from your_module_name import verify_realm_characters

def test_verify_realm_characters_valid():
    realm = "example-realm_123"
    assert verify_realm_characters(realm)

def test_verify_realm_characters_invalid():
    realm = "invalid#realm"
    assert not verify_realm_characters(realm)

def test_verify_realm_characters_empty():
    realm = ""
    assert verify_realm_characters(realm)

def test_verify_realm_characters_dash_at_start():
    realm = "-start-with-dash"
    assert not verify_realm_characters(realm)
