# Password Hashing

This project uses Rails `has_secure_password`, backed by the `bcrypt` gem, for
user password hashing.

## Registration

`POST /auth/register` accepts `password` and `password_confirmation`, but the
database only stores the generated `password_digest` value in the `users` table.
The plaintext password is not persisted.

## Login

`POST /auth/login` verifies the submitted password through
`user.authenticate(password)`. Rails compares the submitted password with the
stored bcrypt digest and returns authentication success only when they match.

## Verification

The test suite covers the hashing behavior by asserting that:

- `password_digest` is different from the submitted plaintext password.
- the digest can be verified by bcrypt.
- login succeeds with the original password and fails with an invalid password.
- API responses do not include `password` or `password_digest`.
