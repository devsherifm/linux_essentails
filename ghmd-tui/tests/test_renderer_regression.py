import pytest


def test_mermaid_sequence_note_does_not_crash():
    pytest.importorskip("rich")
    pytest.importorskip("textual")
    from ghmd.renderer import render_mermaid
    from ghmd.theme import Theme

    result = render_mermaid(
        """sequenceDiagram\nparticipant Client\nparticipant Server\nNote over Client, Server: Connection Establishment\nClient->>Server: SYN (seq=x)\nServer-->>Client: SYN-ACK (seq=y, ack=x+1)""",
        Theme(),
    )
    assert result is not None
