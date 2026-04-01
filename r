conveying_payloads = ConveyingPartyPayloadMapper.generate_payloads(
    owners=conveying_parties,
    assignment_id=assignment_id,
)

for payload in conveying_payloads:
    print("CONVEYING PAYLOAD")
    print(json.dumps(payload, indent=2, default=str))

    conveying_response = requests.post(
        url=conveying_url,
        json=payload,
        headers={
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        verify=False,
        timeout=60,
    )

    print("CONVEYING STATUS:", conveying_response.status_code)
    print("CONVEYING RESPONSE:", conveying_response.text)