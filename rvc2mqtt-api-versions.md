# RVC Spec Decoder API Versioning

The `rvc2mqtt.pl` script loads `rvc-spec.yml`, a machine readable
version of the RV-C specification in YAML format. The file describes how
to decode each byte and bit of the data stream into keys and values.

Since other tools use the mqtt outputs of the script, the decoder spec
is versioned so that any changes to the output can be tracked and
downstream scripts can be updated.

`rvc2mqtt.pl` publishes (and retains) the current API version on mqtt
topic `RVC/API_VERSION`.

## Version 1

Initial release.
