# email

A Motoko library for parsing and validating email addresses.

## Installation

```bash
mops add email
```

## Usage

```motoko
import Email "mo:email/src/lib";

// Parse a single email address
let #ok(email) = Email.parse("John Doe <john.doe@example.com>");

// Parse a list of email addresses
for (result in Email.parseMultiple("jane.doe@example.com, john.doe@example.com")) {
  let #ok(email) = result;
  // ...
};
```

## API

### `parse(input : Text) : Result<Email>`

Parses a single email address from the given text. Returns a `Result` type, which is either an `Email` object or an error message.

### `parseMultiple(input : Text) : Iter.Iter<Result<Email>>`

Parses a comma-separated list of email addresses from the given text. Returns an iterator of `Result` types.

### `type Email`

The `Email` type has the following fields:

*   `comments : [Text]` - A list of comments found in the email address.
*   `raw : Text` - The raw, unparsed email address.
*   `local : Text` - The local part of the email address.
*   `domain : Text` - The domain of the email address.
*   `displayName : Text` - The display name of the email address.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
