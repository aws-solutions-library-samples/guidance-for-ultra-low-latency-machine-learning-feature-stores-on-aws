from datetime import timedelta

import pandas as pd

from feast import (
    Entity,
    Feature,
    FeatureService,
    FeatureView,
    Field,
    PushSource,
    RedshiftSource,
    RequestSource,
    ValueType
)

from feast.types import Float32, Float64, Int64, String

zipcode = Entity(name="zipcode", value_type=ValueType.INT64, join_keys=["zipcode"])

zipcode_source = RedshiftSource(
    table="zipcode_features",
    timestamp_field="event_timestamp",
    created_timestamp_column="created_timestamp",
    schema="spectrum",
    database="dev",
)

zipcode_features = FeatureView(
    name="zipcode_features",
    entities=[zipcode],
    ttl=timedelta(days=3650),
    schema=[
        Field(name="city", dtype=String),
        Field(name="state", dtype=String),
        Field(name="location_type", dtype=String),
        Field(name="tax_returns_filed", dtype=Int64),
        Field(name="population", dtype=Int64),
        Field(name="total_wages", dtype=Int64),
    ],
    source=zipcode_source,
)

dob_ssn = Entity(
    name="dob_ssn",
    value_type=ValueType.STRING,
    join_keys=["dob_ssn"],
)

credit_history_source = RedshiftSource(
    table="credit_history",
    timestamp_field="event_timestamp",
    created_timestamp_column="created_timestamp",
    schema="spectrum",
    database="dev",
)

credit_history = FeatureView(
    name="credit_history",
    entities=[dob_ssn],
    ttl=timedelta(days=3650),
    schema=[
        Field(name="credit_card_due", dtype=Int64),
        Field(name="mortgage_due", dtype=Int64),
        Field(name="student_loan_due", dtype=Int64),
        Field(name="vehicle_loan_due", dtype=Int64),
        Field(name="hard_pulls", dtype=Int64),
        Field(name="missed_payments_2y", dtype=Int64),
        Field(name="missed_payments_1y", dtype=Int64),
        Field(name="missed_payments_6m", dtype=Int64),
        Field(name="bankruptcies", dtype=Int64),
    ],
    source=credit_history_source,
)
