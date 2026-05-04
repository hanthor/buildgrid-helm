BEGIN;

CREATE TABLE alembic_version (
    version_num VARCHAR(32) NOT NULL, 
    CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num)
);

-- Running upgrade  -> 0c17a7cb2bc5

CREATE TABLE blobs (
    digest_hash VARCHAR NOT NULL, 
    digest_size_bytes BIGINT NOT NULL, 
    data BYTEA NOT NULL, 
    PRIMARY KEY (digest_hash)
);

CREATE TABLE bots (
    name VARCHAR NOT NULL, 
    bot_id VARCHAR NOT NULL, 
    instance_name VARCHAR NOT NULL, 
    bot_status INTEGER NOT NULL, 
    lease_id VARCHAR, 
    expiry_time TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
    last_update_timestamp TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
    PRIMARY KEY (name)
);

CREATE INDEX ix_bots_bot_id ON bots (bot_id);

CREATE INDEX ix_bots_expiry_time ON bots (expiry_time);

CREATE INDEX ix_bots_last_update_timestamp ON bots (last_update_timestamp);

CREATE INDEX ix_bots_name ON bots (name);

CREATE TABLE client_identities (
    id SERIAL NOT NULL, 
    instance VARCHAR NOT NULL, 
    workflow VARCHAR NOT NULL, 
    actor VARCHAR NOT NULL, 
    subject VARCHAR NOT NULL, 
    PRIMARY KEY (id), 
    UNIQUE (instance, workflow, actor, subject)
);

CREATE TABLE index (
    digest_hash VARCHAR NOT NULL, 
    digest_size_bytes BIGINT NOT NULL, 
    accessed_timestamp TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
    deleted BOOLEAN DEFAULT false NOT NULL, 
    inline_blob BYTEA, 
    PRIMARY KEY (digest_hash)
);

CREATE INDEX ix_index_accessed_timestamp ON index (accessed_timestamp);

CREATE INDEX ix_index_digest_hash ON index (digest_hash);

CREATE TABLE jobs (
    name VARCHAR NOT NULL, 
    instance_name VARCHAR NOT NULL, 
    action_digest VARCHAR NOT NULL, 
    action BYTEA NOT NULL, 
    do_not_cache BOOLEAN NOT NULL, 
    platform_requirements VARCHAR NOT NULL, 
    property_label VARCHAR DEFAULT 'unknown' NOT NULL, 
    command VARCHAR NOT NULL, 
    stage INTEGER NOT NULL, 
    priority INTEGER NOT NULL, 
    cancelled BOOLEAN NOT NULL, 
    assigned BOOLEAN NOT NULL, 
    n_tries INTEGER NOT NULL, 
    result VARCHAR, 
    status_code INTEGER, 
    create_timestamp TIMESTAMP WITHOUT TIME ZONE, 
    queued_timestamp TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
    queued_time_duration INTEGER, 
    worker_start_timestamp TIMESTAMP WITHOUT TIME ZONE, 
    worker_completed_timestamp TIMESTAMP WITHOUT TIME ZONE, 
    input_fetch_start_timestamp TIMESTAMP WITHOUT TIME ZONE, 
    input_fetch_completed_timestamp TIMESTAMP WITHOUT TIME ZONE, 
    output_upload_start_timestamp TIMESTAMP WITHOUT TIME ZONE, 
    output_upload_completed_timestamp TIMESTAMP WITHOUT TIME ZONE, 
    execution_start_timestamp TIMESTAMP WITHOUT TIME ZONE, 
    execution_completed_timestamp TIMESTAMP WITHOUT TIME ZONE, 
    stdout_stream_name VARCHAR, 
    stdout_stream_write_name VARCHAR, 
    stderr_stream_name VARCHAR, 
    stderr_stream_write_name VARCHAR, 
    PRIMARY KEY (name)
);

CREATE INDEX ix_jobs_action_digest ON jobs (action_digest);

CREATE INDEX ix_jobs_instance_name ON jobs (instance_name);

CREATE INDEX ix_jobs_priority ON jobs (priority);

CREATE INDEX ix_jobs_queued_timestamp ON jobs (queued_timestamp);

CREATE INDEX ix_jobs_stage_property_label ON jobs (stage, property_label);

CREATE INDEX ix_worker_completed_timestamp ON jobs (worker_completed_timestamp) WHERE worker_completed_timestamp IS NOT NULL;

CREATE INDEX ix_worker_start_timestamp ON jobs (worker_start_timestamp) WHERE worker_start_timestamp IS NOT NULL;

CREATE TABLE platform_properties (
    id SERIAL NOT NULL, 
    key VARCHAR NOT NULL, 
    value VARCHAR NOT NULL, 
    PRIMARY KEY (id), 
    UNIQUE (key, value)
);

CREATE TABLE request_metadata (
    id SERIAL NOT NULL, 
    tool_name VARCHAR, 
    tool_version VARCHAR, 
    invocation_id VARCHAR, 
    correlated_invocations_id VARCHAR, 
    action_mnemonic VARCHAR, 
    target_id VARCHAR, 
    configuration_id VARCHAR, 
    PRIMARY KEY (id), 
    CONSTRAINT unique_metadata_constraint UNIQUE (tool_name, tool_version, invocation_id, correlated_invocations_id, action_mnemonic, target_id, configuration_id)
);

CREATE TABLE job_platforms (
    job_name VARCHAR NOT NULL, 
    platform_id INTEGER NOT NULL, 
    PRIMARY KEY (job_name, platform_id), 
    FOREIGN KEY(job_name) REFERENCES jobs (name) ON DELETE CASCADE ON UPDATE CASCADE, 
    FOREIGN KEY(platform_id) REFERENCES platform_properties (id)
);

CREATE TABLE leases (
    id SERIAL NOT NULL, 
    job_name VARCHAR NOT NULL, 
    status INTEGER, 
    state INTEGER NOT NULL, 
    worker_name VARCHAR, 
    PRIMARY KEY (id), 
    FOREIGN KEY(job_name) REFERENCES jobs (name) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX ix_leases_job_name ON leases (job_name);

CREATE INDEX ix_leases_worker_name ON leases (worker_name);

CREATE TABLE operations (
    name VARCHAR NOT NULL, 
    cancelled BOOLEAN NOT NULL, 
    tool_name VARCHAR, 
    tool_version VARCHAR, 
    invocation_id VARCHAR, 
    correlated_invocations_id VARCHAR, 
    job_name VARCHAR NOT NULL, 
    client_identity_id INTEGER, 
    request_metadata_id INTEGER, 
    PRIMARY KEY (name), 
    FOREIGN KEY(client_identity_id) REFERENCES client_identities (id), 
    FOREIGN KEY(job_name) REFERENCES jobs (name) ON DELETE CASCADE ON UPDATE CASCADE, 
    FOREIGN KEY(request_metadata_id) REFERENCES request_metadata (id)
);

CREATE INDEX ix_operations_job_name ON operations (job_name);

INSERT INTO alembic_version (version_num) VALUES ('0c17a7cb2bc5') RETURNING alembic_version.version_num;

-- Running upgrade 0c17a7cb2bc5 -> 910398062924

CREATE TABLE property_labels (
    id SERIAL NOT NULL, 
    property_label VARCHAR NOT NULL, 
    bot_name VARCHAR NOT NULL, 
    PRIMARY KEY (id), 
    FOREIGN KEY(bot_name) REFERENCES bots (name) ON DELETE CASCADE
);

CREATE INDEX ix_property_labels_bot_name ON property_labels (bot_name);

CREATE INDEX ix_property_labels_property_label ON property_labels (property_label);

UPDATE alembic_version SET version_num='910398062924' WHERE alembic_version.version_num = '0c17a7cb2bc5';

-- Running upgrade 910398062924 -> 55fcf6c874d3

ALTER TABLE operations DROP COLUMN correlated_invocations_id;

ALTER TABLE operations DROP COLUMN invocation_id;

ALTER TABLE operations DROP COLUMN tool_version;

ALTER TABLE operations DROP COLUMN tool_name;

UPDATE alembic_version SET version_num='55fcf6c874d3' WHERE alembic_version.version_num = '910398062924';

-- Running upgrade 55fcf6c874d3 -> 9ecd996412a9

ALTER TABLE jobs ADD COLUMN worker_name VARCHAR;

CREATE INDEX ix_jobs_worker_name ON jobs (worker_name);

UPDATE alembic_version SET version_num='9ecd996412a9' WHERE alembic_version.version_num = '55fcf6c874d3';

-- Running upgrade 9ecd996412a9 -> 1f959c3834d3

DROP TABLE leases;

UPDATE alembic_version SET version_num='1f959c3834d3' WHERE alembic_version.version_num = '9ecd996412a9';

-- Running upgrade 1f959c3834d3 -> 9e7a59ee4370

CREATE TABLE bot_platforms (
    bot_name VARCHAR NOT NULL, 
    platform VARCHAR NOT NULL, 
    PRIMARY KEY (bot_name, platform), 
    FOREIGN KEY(bot_name) REFERENCES bots (name) ON DELETE CASCADE
);

CREATE INDEX ix_bot_platforms_platform ON bot_platforms (platform) INCLUDE (bot_name);

CREATE INDEX ix_bots_instance_name ON bots (instance_name);

ALTER TABLE jobs ADD COLUMN schedule_after TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL;

UPDATE alembic_version SET version_num='9e7a59ee4370' WHERE alembic_version.version_num = '1f959c3834d3';

-- Running upgrade 9e7a59ee4370 -> 5745d1f0e537

DROP INDEX ix_bots_name;

DROP INDEX ix_jobs_priority;

DROP INDEX ix_worker_start_timestamp;

CREATE INDEX ix_jobs_priority_timestamp_scheduling ON jobs (priority, queued_timestamp, schedule_after) WHERE stage = 2 AND assigned != true;

UPDATE alembic_version SET version_num='5745d1f0e537' WHERE alembic_version.version_num = '9e7a59ee4370';

-- Running upgrade 5745d1f0e537 -> 0596ea8f5c61

CREATE SEQUENCE bot_locality_hints_sequence AS BIGINT INCREMENT BY 1 START WITH 1 CYCLE;

CREATE TABLE bot_locality_hints (
    id SERIAL NOT NULL, 
    bot_name VARCHAR NOT NULL, 
    locality_hint VARCHAR NOT NULL, 
    sequence_number BIGINT DEFAULT nextval('bot_locality_hints_sequence') NOT NULL, 
    PRIMARY KEY (id), 
    FOREIGN KEY(bot_name) REFERENCES bots (name) ON DELETE CASCADE
);

CREATE INDEX ix_bot_locality_hints_bot_name_sequence_number ON bot_locality_hints (bot_name, sequence_number);

CREATE INDEX ix_bot_locality_hints_locality_hint ON bot_locality_hints (locality_hint);

ALTER TABLE jobs ADD COLUMN locality_hint VARCHAR;

UPDATE alembic_version SET version_num='0596ea8f5c61' WHERE alembic_version.version_num = '5745d1f0e537';

-- Running upgrade 0596ea8f5c61 -> 8fd7118e215e

CREATE INDEX ix_jobs_instance_priority_timestamp_scheduling ON jobs (priority, queued_timestamp, instance_name, schedule_after) WHERE stage = 2 AND assigned != true;

UPDATE alembic_version SET version_num='8fd7118e215e' WHERE alembic_version.version_num = '0596ea8f5c61';

-- Running upgrade 8fd7118e215e -> b3b9d7300155

ALTER TABLE bots ADD COLUMN capacity INTEGER DEFAULT 1 NOT NULL;

UPDATE alembic_version SET version_num='b3b9d7300155' WHERE alembic_version.version_num = '8fd7118e215e';

-- Running upgrade b3b9d7300155 -> fb8afebee8e6

DROP INDEX ix_jobs_worker_name;

CREATE INDEX ix_jobs_worker_name_stage ON jobs (worker_name, stage) WHERE worker_name IS NOT NULL;

UPDATE alembic_version SET version_num='fb8afebee8e6' WHERE alembic_version.version_num = 'b3b9d7300155';

-- Running upgrade fb8afebee8e6 -> d850621a10d8

ALTER TABLE jobs ADD COLUMN assigner_name VARCHAR;

UPDATE alembic_version SET version_num='d850621a10d8' WHERE alembic_version.version_num = 'fb8afebee8e6';

-- Running upgrade d850621a10d8 -> bde0df23383b

ALTER TABLE bots ADD COLUMN cohort VARCHAR;

UPDATE alembic_version SET version_num='bde0df23383b' WHERE alembic_version.version_num = 'd850621a10d8';

-- Running upgrade bde0df23383b -> 22cc661efef9

CREATE TABLE instance_quotas (
    bot_cohort VARCHAR NOT NULL, 
    instance_name VARCHAR NOT NULL, 
    min_quota INTEGER DEFAULT 0 NOT NULL, 
    max_quota INTEGER DEFAULT 0 NOT NULL, 
    current_usage INTEGER DEFAULT 0 NOT NULL, 
    PRIMARY KEY (bot_cohort, instance_name)
);

UPDATE alembic_version SET version_num='22cc661efef9' WHERE alembic_version.version_num = 'bde0df23383b';

-- Running upgrade 22cc661efef9 -> 90bd87d052a0

CREATE TABLE job_history (
    id SERIAL NOT NULL, 
    event_type INTEGER NOT NULL, 
    job_name VARCHAR NOT NULL, 
    timestamp TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
    payload JSONB, 
    PRIMARY KEY (id), 
    FOREIGN KEY(job_name) REFERENCES jobs (name) ON DELETE CASCADE
);

CREATE INDEX ix_job_history_job_name ON job_history (job_name);

UPDATE alembic_version SET version_num='90bd87d052a0' WHERE alembic_version.version_num = '22cc661efef9';

-- Running upgrade 90bd87d052a0 -> 12992085e81a

CREATE INDEX ix_jobs_worker_name_incomplete ON jobs (worker_name, stage) WHERE worker_name IS NOT NULL AND stage < 4;

UPDATE alembic_version SET version_num='12992085e81a' WHERE alembic_version.version_num = '90bd87d052a0';

-- Running upgrade 12992085e81a -> 5b90ed0e9d0b

DROP INDEX ix_jobs_worker_name_stage;

UPDATE alembic_version SET version_num='5b90ed0e9d0b' WHERE alembic_version.version_num = '12992085e81a';

-- Running upgrade 5b90ed0e9d0b -> 55acd9b4ec38

CREATE INDEX ix_jobs_property_label_stage ON jobs (property_label, stage) WHERE stage < 4;

UPDATE alembic_version SET version_num='55acd9b4ec38' WHERE alembic_version.version_num = '5b90ed0e9d0b';

-- Running upgrade 55acd9b4ec38 -> 85096c931383

DROP INDEX ix_jobs_priority_timestamp_scheduling;

DROP INDEX ix_jobs_stage_property_label;

UPDATE alembic_version SET version_num='85096c931383' WHERE alembic_version.version_num = '55acd9b4ec38';

-- Running upgrade 85096c931383 -> 8f7f43e4a833

ALTER TABLE bots ADD COLUMN max_capacity INTEGER DEFAULT 1 NOT NULL;

UPDATE alembic_version SET version_num='8f7f43e4a833' WHERE alembic_version.version_num = '85096c931383';

-- Running upgrade 8f7f43e4a833 -> ff09fbc30c3e

ALTER TABLE bots ADD COLUMN version BIGINT DEFAULT 0 NOT NULL;

UPDATE alembic_version SET version_num='ff09fbc30c3e' WHERE alembic_version.version_num = '8f7f43e4a833';

-- Running upgrade ff09fbc30c3e -> 3737630fc9cf

ALTER TABLE index DROP COLUMN deleted;

UPDATE alembic_version SET version_num='3737630fc9cf' WHERE alembic_version.version_num = 'ff09fbc30c3e';

-- Running upgrade 3737630fc9cf -> d1de6a7df71e

CREATE TABLE eviction_log (
    id SERIAL NOT NULL, 
    job_name VARCHAR NOT NULL, 
    instance_name VARCHAR NOT NULL, 
    bot_cohort VARCHAR NOT NULL, 
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT (now() AT TIME ZONE 'UTC') NOT NULL, 
    PRIMARY KEY (id), 
    FOREIGN KEY(job_name) REFERENCES jobs (name) ON DELETE CASCADE
);

CREATE INDEX ix_eviction_log_instance_bot_cohort_timestamp ON eviction_log (instance_name, bot_cohort, timestamp);

UPDATE alembic_version SET version_num='d1de6a7df71e' WHERE alembic_version.version_num = '3737630fc9cf';

-- Running upgrade d1de6a7df71e -> 146448692d39

ALTER TABLE jobs ADD COLUMN preferred_requirements VARCHAR;

ALTER TABLE jobs ADD COLUMN preferred_label VARCHAR;

UPDATE alembic_version SET version_num='146448692d39' WHERE alembic_version.version_num = 'd1de6a7df71e';

-- Running upgrade 146448692d39 -> b1d6fb2ff810

ALTER TABLE bots ADD COLUMN priority INTEGER DEFAULT 0 NOT NULL;

UPDATE alembic_version SET version_num='b1d6fb2ff810' WHERE alembic_version.version_num = '146448692d39';

-- Running upgrade b1d6fb2ff810 -> 2b5f9653537e

CREATE INDEX ix_jobs_instance_priority_timestamp_requirements_scheduling ON jobs (priority, queued_timestamp, instance_name, platform_requirements, schedule_after) WHERE stage = 2 AND assigned != true;

UPDATE alembic_version SET version_num='2b5f9653537e' WHERE alembic_version.version_num = 'b1d6fb2ff810';

COMMIT;

