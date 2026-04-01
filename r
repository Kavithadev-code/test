from typing import Any, Dict, List, Optional


class ReceivingPartyPayloadMapper:
    @staticmethod
    def generate_payloads(
        owners: List[Any],
        assignment_id: int,
        form_type: str = "TRADEMARK",
    ) -> List[Dict[str, Any]]:
        payloads: List[Dict[str, Any]] = []

        for owner in owners or []:
            payload = ReceivingPartyPayloadMapper._map_owner(
                owner=owner,
                assignment_id=assignment_id,
                form_type=form_type,
            )
            if payload:
                payloads.append(payload)

        return payloads

    @staticmethod
    def _map_owner(
        owner: Any,
        assignment_id: int,
        form_type: str,
    ) -> Optional[Dict[str, Any]]:
        ip_info = ReceivingPartyPayloadMapper._get_value(owner, "ip_info", "ipInfo")
        if not ip_info:
            return None

        party_code = ReceivingPartyPayloadMapper._get_value(ip_info, "party_code", "partyCode")
        legal_entity = ReceivingPartyPayloadMapper._get_value(
            ip_info, "legal_entity", "legalEntity"
        )
        full_name = ReceivingPartyPayloadMapper._get_value(ip_info, "name")
        given_name = ReceivingPartyPayloadMapper._get_value(ip_info, "given_name", "givenName")
        family_name = ReceivingPartyPayloadMapper._get_value(ip_info, "family_name", "familyName")
        middle_name = ReceivingPartyPayloadMapper._get_value(ip_info, "middle_name", "middleName")
        prefix_name = ReceivingPartyPayloadMapper._get_value(ip_info, "prefix_name", "prefixName")
        suffix = ReceivingPartyPayloadMapper._get_value(ip_info, "suffix")

        first_name, last_name = ReceivingPartyPayloadMapper._derive_names(
            given_name=given_name,
            family_name=family_name,
            full_name=full_name,
        )

        contact_address = ReceivingPartyPayloadMapper._get_value(
            ip_info, "contact_address", "contactAddress"
        )
        mailing_addresses = ReceivingPartyPayloadMapper._get_value(
            contact_address, "mailing_addresses", "mailingAddresses"
        ) or []
        first_mailing = mailing_addresses[0] if mailing_addresses else None

        domestic_address_info = None
        if first_mailing:
            domestic_address_info = {
                "address_1": ReceivingPartyPayloadMapper._get_value(
                    first_mailing, "street_address_line_text", "streetAddressLineText"
                ),
                "address_2": ReceivingPartyPayloadMapper._get_value(
                    first_mailing, "free_format_address", "freeFormatAddress"
                ),
                "city": ReceivingPartyPayloadMapper._get_value(
                    first_mailing, "city_name", "cityName"
                ),
                "state": ReceivingPartyPayloadMapper._get_value(
                    first_mailing, "state_geo_code", "stateGeoCode"
                ),
                "zip": ReceivingPartyPayloadMapper._get_value(
                    first_mailing, "postal_code", "postalCode"
                ),
                "country": ReceivingPartyPayloadMapper._get_value(
                    first_mailing, "country_name", "countryName"
                ),
                "lock_control_number": 1,
            }

        payload: Dict[str, Any] = {
            "assignmentId": assignment_id,
            "formType": form_type,
            "receiving_type": "INDIVIDUAL" if party_code == "I" else "ENTITY",
            "representative": None,
            "domestic_individual": None,
            "domestic_address_info": domestic_address_info,
            "composed_party_list": [],
        }

        if party_code == "I":
            payload["receiving_party"] = {
                "prefix": prefix_name,
                "first_name": first_name,
                "middle_name": middle_name,
                "last_name": last_name,
                "suffix": suffix,
                "lock_control_number": 1,
            }
        else:
            payload["receiving_party"] = {
                "entity_name": full_name,
                "legal_entity_type_id": legal_entity,
                "lock_control_number": 1,
            }

        return payload

    @staticmethod
    def _derive_names(
        given_name: Optional[str],
        family_name: Optional[str],
        full_name: Optional[str],
    ) -> tuple[Optional[str], Optional[str]]:
        if given_name:
            return given_name, family_name

        if not full_name:
            return None, None

        if "," in full_name:
            parts = [p.strip() for p in full_name.split(",") if p.strip()]
            if len(parts) >= 2:
                return parts[1], parts[0]

        parts = [p.strip() for p in full_name.split() if p.strip()]
        if len(parts) >= 2:
            return " ".join(parts[:-1]), parts[-1]

        return full_name, full_name

    @staticmethod
    def _get_value(obj: Any, *names: str) -> Any:
        if obj is None:
            return None

        for name in names:
            if isinstance(obj, dict) and name in obj:
                return obj.get(name)

            if hasattr(obj, name):
                return getattr(obj, name)

            unknown_fields = getattr(obj, "unknown_fields", None)
            if isinstance(unknown_fields, dict) and name in unknown_fields:
                return unknown_fields.get(name)

        return None
