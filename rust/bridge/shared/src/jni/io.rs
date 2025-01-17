//
// Copyright 2023 Signal Messenger, LLC.
// SPDX-License-Identifier: AGPL-3.0-only
//

use std::cell::RefCell;
use std::io;

use async_trait::async_trait;
use bytemuck::cast_slice_mut;

use super::*;

use crate::io::{InputStream, InputStreamRead};

pub type JavaInputStream<'a> = JObject<'a>;

pub struct JniInputStream<'a> {
    env: RefCell<EnvHandle<'a>>,
    stream: &'a JObject<'a>,
}

impl<'a> JniInputStream<'a> {
    pub fn new<'context: 'a>(
        env: &mut JNIEnv<'context>,
        stream: &'a JObject<'a>,
    ) -> SignalJniResult<Self> {
        check_jobject_type(env, stream, jni_class_name!(java.io.InputStream))?;
        Ok(Self {
            env: EnvHandle::new(env).into(),
            stream,
        })
    }

    fn do_read(&self, buf: &mut [u8]) -> SignalJniResult<usize> {
        self.env.borrow_mut().with_local_frame(8, |env| {
            let java_buf = env.new_byte_array(buf.len() as i32)?;
            let amount_read: jint = call_method_checked(
                env,
                self.stream,
                "read",
                jni_args!((java_buf => [byte]) -> int),
            )?;
            let amount_read = match amount_read {
                -1 => 0,
                _ => u32::convert_from(env, &amount_read)? as usize,
            };
            env.get_byte_array_region(java_buf, 0, cast_slice_mut(&mut buf[..amount_read]))?;
            Ok(amount_read)
        })
    }

    fn do_skip(&self, amount: u64) -> SignalJniResult<()> {
        self.env.borrow_mut().with_local_frame(8, |env| {
            let java_amount = amount.try_into().map_err(|_| {
                SignalJniError::Io(io::Error::new(
                    io::ErrorKind::UnexpectedEof,
                    "InputStream::skip more than i64::MAX not supported",
                ))
            })?;

            let amount_skipped: jlong = call_method_checked(
                env,
                self.stream,
                "skip",
                jni_args!((java_amount => long) -> long),
            )?;

            if amount_skipped != java_amount {
                return Err(SignalJniError::Io(io::Error::new(
                    io::ErrorKind::UnexpectedEof,
                    "InputStream skipped less than requested",
                )));
            }
            Ok(())
        })
    }
}

#[async_trait(?Send)]
impl InputStream for JniInputStream<'_> {
    fn read<'out, 'a: 'out>(&'a self, buf: &mut [u8]) -> io::Result<InputStreamRead<'out>> {
        let amount_read = self.do_read(buf)?;
        Ok(InputStreamRead::Ready { amount_read })
    }

    async fn skip(&self, amount: u64) -> io::Result<()> {
        self.do_skip(amount)?;
        Ok(())
    }
}
