// Inspired by : https://github.com/chronotope/chrono/pull/1244/files

use chrono::{DateTime, FixedOffset, Utc};
use std::cell::RefCell;

thread_local!(
    pub(super) static OVERRIDE_NOW: RefCell<Option<DateTime<FixedOffset>>> = const { RefCell::new(None) }
);

// To override the time. Needed for tests.
pub fn override_now(datetime: Option<DateTime<FixedOffset>>) {
    OVERRIDE_NOW.with(|o| *o.borrow_mut() = datetime)
}

// Function to use instead of Utc::now straight.
pub fn now() -> DateTime<Utc> {
    if let Some(t) = OVERRIDE_NOW.with(|o| *o.borrow()) {
        return t.into();
    }

    Utc::now()
}
