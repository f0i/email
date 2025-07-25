import Iter "mo:core/Iter";
import Text "mo:core/Text";
import Array "mo:core/Array";
import { print } "mo:core/Debug";
import Runtime "mo:core/Runtime";
import Char "mo:core/Char";
import List "mo:core/List";
import Debug "mo:core/Debug";

module {
  public func slice(s : Text, fromInclusive : Nat, toExclusive : Nat) : Text {
    if (fromInclusive > toExclusive) print(debug_show (s, fromInclusive, toExclusive));
    let arr = Text.toArray(s);
    let slicedArr = Array.sliceToArray(arr, fromInclusive, toExclusive);
    return Text.fromArray(slicedArr);
  };

  public func reverse(s : Text) : Text {
    Text.toArray(s)
    |> Array.reverse(_)
    |> Text.fromArray(_);
  };

  public func splitOnUnquotedChar(text : Text, sep : Char) : Iter.Iter<Text> {
    splitOnUnquoted(text, func(c : Char) : Bool = c == sep);
  };

  /// Split text on a character that is not inside quotes or after an escape character
  /// The iter returns at least one item
  /// The last element can contain unclosed quoted strings, unclosed comments or unfinished escape sequences.
  public func splitOnUnquoted(text : Text, isSep : Char -> Bool) : Iter.Iter<Text> {
    var escaped = false;
    var quoted = false;
    var depth = 0;
    var start = 0;
    let size = Text.size(text);
    var last = false;
    let iter = Iter.enumerate(text.chars());

    return {
      next = func() : ?Text {
        for ((i, c) in iter) {
          if (escaped) {
            escaped := false;
          } else if (c == '\\') {
            // Escaped backslash
            escaped := true;
          } else if (depth == 0 and c == '\"') {
            quoted := not quoted;
            // ignore in quoted
          } else if (not escaped and c == '(') {
            depth += 1;
          } else if (not escaped and c == ')') {
            if (depth == 0) Runtime.trap("Unmatchd closing comment");
            depth -= 1;
          } else if (depth == 0 and not quoted and isSep(c)) {
            let part = slice(text, start, i);
            start := i + 1;
            // separator found
            return ?part;
          };
        };

        if (not last) {
          let part = slice(text, start, size);
          last := true;
          return ?part;
        };

        return null;
      };
    };
  };

  /// Split the data on the first unquoted occurence of a separator
  /// Returns an array with one or two elements
  public func splitOnFirstUnquoted(text : Text, isSep : Char -> Bool) : [Text] {
    let iter = splitOnUnquoted(text, isSep);
    let ?first = iter.next() else Runtime.unreachable();
    let size = Text.size(text);
    let firstSize = Text.size(first);
    if (firstSize == size) return [first];
    let second = slice(text, firstSize + 1, size);
    return [first, second];
  };

  /// Split the data on the last unquoted occurence of a separator
  /// Returns an array with one or two elements
  public func splitOnLastUnquoted(text : Text, isSep : Char -> Bool) : [Text] {
    let iter = splitOnUnquoted(text, isSep);
    let ?first = iter.next() else Runtime.unreachable();

    var last = first;
    for (part in iter) {
      last := part;
    };

    let size = Text.size(text);
    let lastSize = Text.size(last);
    if (lastSize == size) return [last];
    let pre = slice(text, 0, size - lastSize);
    return [pre, last];
  };

  /// Parse the part before @
  ///
  public func splitPre(input : Text) : { local : Text; display : Text } {
    let parts = splitOnLastUnquoted(input, Char.isWhitespace);
    if (parts.size() == 2) return { local = parts[1]; display = parts[0] };
    if (parts.size() == 1) return { local = parts[0]; display = "" };

    Runtime.unreachable();
  };

  /// Split the part after @ into domain part and post domain part
  /// This will not remove comments or invalid characters
  public func splitPost(input : Text) : { domain : Text; post : Text } {
    let parts = splitOnFirstUnquoted(input, Char.isWhitespace);
    if (parts.size() == 2) return { domain = parts[0]; post = parts[1] };
    if (parts.size() == 1) return { domain = parts[0]; post = "" };

    Runtime.unreachable();
  };

  /// Remove the comments from any position inside the input text
  public func parseComments(input : Text) : {
    rest : Text;
    comments : [Text];
  } {
    // print(debug_show ("parseDisplay", input));
    let comments = List.empty<Text>();
    var rest = input;
    label commentLoop loop {
      let parts = removeComment(rest);
      rest := parts.rest;
      if (parts.comment == "") break commentLoop;
      List.add(comments, parts.comment);
    };

    return {
      rest = Text.trim(rest, #predicate(Char.isWhitespace));
      comments = List.toArray(comments);
    };
  };

  /// parse the part after @ until the first whitespace
  /// separate comments and the potential domain name
  public func parseDomain(input : Text) : {
    comments : [Text];
    domain : Text;
    isAngleWrapped : Bool;
  } {
    var rest : Text = input;
    let comments = List.empty<Text>();
    var isAngleWrapped = false;

    while (Text.startsWith(rest, #char '(')) {
      let res = removeLeadingComment(rest);
      rest := res.rest;
      List.add(comments, res.comment);
    };

    let commentsAfter = List.empty<Text>();
    while (Text.endsWith(rest, #char ')')) {
      let res = removeTailingComment(rest);
      rest := res.rest;
      List.add(commentsAfter, res.comment);
    };

    if (Text.endsWith(rest, #char('>'))) {
      rest := slice(rest, 0, rest.size() - 1);
      isAngleWrapped := true;
    };

    // remove comments inside angle bracket
    while (Text.endsWith(rest, #char ')')) {
      let res = removeTailingComment(rest);
      rest := res.rest;
      List.add(commentsAfter, res.comment);
    };

    return {
      domain = rest;
      comments = List.toArray(List.reverse(comments));
      isAngleWrapped;
    };
  };

  // Parse the local part with comments
  public func parseLocal(input : Text) : {
    comments : [Text];
    local : Text;
    isAngleWrapped : Bool;
  } {
    var rest : Text = input;
    let comments = List.empty<Text>();
    var isAngleWrapped = false;

    while (Text.startsWith(rest, #char '(')) {
      let res = removeLeadingComment(rest);
      rest := res.rest;
      List.add(comments, res.comment);
    };

    let commentsAfter = List.empty<Text>();
    while (Text.endsWith(rest, #char ')')) {
      let res = removeTailingComment(rest);
      rest := res.rest;
      List.add(commentsAfter, res.comment);
    };

    if (Text.startsWith(rest, #char('<'))) {
      rest := slice(rest, 1, rest.size());
      isAngleWrapped := true;
    };

    // remove comments inside angle bracket
    while (Text.startsWith(rest, #char '(')) {
      let res = removeLeadingComment(rest);
      rest := res.rest;
      List.add(comments, res.comment);
    };

    return {
      local = rest;
      comments = List.toArray(List.reverse(comments));
      isAngleWrapped;
    };
  };

  public func removeLeadingComment(input : Text) : {
    comment : Text;
    rest : Text;
  } {
    assert Text.startsWith(input, #char('('));
    let iter = Iter.enumerate(input.chars());

    var inEscape = false;
    var quoted = false;
    var depth = 0;
    var commentEnd = 0;

    label charLoop for ((i, c) in iter) {
      if (inEscape) {
        inEscape := false;
      } else if (c == '\\') {
        inEscape := true;
      } else if (depth == 0 and c == '\"') {
        quoted := not quoted;
      } else if (depth == 0 and quoted) {
        // ignore in quoted
      } else if (not quoted and c == '(') {
        depth += 1;
      } else if (not quoted and c == ')') {
        depth -= 1;
        if (depth == 0) {
          commentEnd := i + 1;
          break charLoop;
        };
      };
    };

    if (commentEnd == 0) Runtime.trap("Comment incomplete");
    let comment = slice(input, 0, commentEnd);
    let rest = slice(input, commentEnd, Text.size(input));

    return { comment; rest };
  };

  public func removeTailingComment(input : Text) : {
    comment : Text;
    rest : Text;
  } {
    assert Text.endsWith(input, #char(')'));
    let iter = Iter.enumerate(input.chars());

    var inEscape = false;
    var quoted = false;
    var depth = 0;
    var commentStart = Text.size(input);

    label charLoop for ((i, c) in iter) {
      if (inEscape) {
        inEscape := false;
      } else if (c == '\\') {
        inEscape := true;
      } else if (depth == 0 and c == '\"') {
        quoted := not quoted;
      } else if (c == '(') {
        if (depth == 0) {
          commentStart := i;
        };
        depth += 1;
      } else if (c == ')') {
        depth -= 1;
      };
    };

    if (quoted) Runtime.trap("unclosed quoted string");
    if (depth > 0) Runtime.trap("unclosed comment");
    if (commentStart == input.size()) Runtime.trap("Comment incomplete");
    let comment = slice(input, commentStart, input.size());
    let rest = slice(input, 0, commentStart);

    return { comment; rest };
  };

  public func removeComment(input : Text) : {
    comment : Text;
    rest : Text;
  } {
    let iter = Iter.enumerate(input.chars());

    var inEscape = false;
    var quoted = false;
    var depth = 0;
    var commentStart = 0;
    var commentEnd = 0;

    label charLoop for ((i, c) in iter) {
      if (inEscape) {
        inEscape := false;
      } else if (c == '\\') {
        inEscape := true;
      } else if (depth == 0 and c == '\"') {
        quoted := not quoted;
      } else if (not quoted and c == '(') {
        if (depth == 0) {
          commentStart := i;
        };
        depth += 1;
      } else if (not quoted and c == ')') {
        if (depth == 0) {
          Runtime.trap("Unmatched closing comment in " # input);
        };
        depth -= 1;

        if (depth == 0) {
          commentEnd := i + 1;
          break charLoop;
        };
      };
    };

    if (quoted) Runtime.trap("unclosed quoted string");
    if (depth > 0) Runtime.trap("unclosed comment");

    let comment = slice(input, commentStart, commentEnd);
    let rest = slice(input, 0, commentStart) # slice(input, commentEnd, input.size());

    return { comment; rest };
  };

};
