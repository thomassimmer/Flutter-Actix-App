// Inspired by : https://github.com/chronotope/chrono/pull/1244/files

use chrono::{DateTime, FixedOffset, Utc};
use std::cell::RefCell;

thread_local!(
    pub(super) static OVERRIDE_NOW: RefCell<Option<DateTime<FixedOffset>>> = const { RefCell::new(None) }
);

pub fn override_now(datetime: Option<DateTime<FixedOffset>>) {
    OVERRIDE_NOW.with(|o| *o.borrow_mut() = datetime)
}

pub fn now() -> DateTime<Utc> {
    if let Some(t) = OVERRIDE_NOW.with(|o| *o.borrow()) {
        return t.into();
    }

    Utc::now()
}
