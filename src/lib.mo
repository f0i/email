import Utils "utils";
import Iter "mo:core/Iter";
import Debug "mo:core/Debug";
import { print } "mo:core/Debug";
import Runtime "mo:core/Runtime";
import Result "mo:core/Result";
import Array "mo:core/Array";
import Text "mo:core/Text";
import { splitPre; splitPost; parseLocal; parseComments; parseDomain } "utils";
import { validateLocal; validateDisplay; validateDomain } "validate";

module {
  // This comment will not be included in the documentation
  // Use triple slash for documentation

  /// Email address split into its parts
  public type Email = {
    comments : [Text];
    raw : Text;
    local : Text;
    domain : Text;
    displayName : Text;
  };
  public type Result<T> = Result.Result<T, Text>;

  /// Parse and validate a single email address
  /// returns a Email with the different parts of the address separated
  public func parse(input : Text) : Result<Email> {
    let parts = Utils.splitOnUnquotedChar(input, '@');
    let ?pre = parts.next() else Runtime.unreachable();
    let ?post = parts.next() else return #err("Missing @ symbol");
    let null = parts.next() else return #err("Multiple @ symbols");

    let preParts = splitPre(pre);
    let postParts = splitPost(post);

    let localParts = parseLocal(preParts.local);

    let displayParts = parseComments(preParts.display);
    if (not validateDisplay(displayParts.rest)) return #err("Invalid display name: " # displayParts.rest);
    let displayName = displayParts.rest;
    let hasDisplay = displayName != "";

    if (not validateLocal(localParts.local)) return #err("Invalid local part: " # localParts.local);
    let local = localParts.local;
    if (hasDisplay and not localParts.isAngleWrapped) return #err("Missing < around email with display name: " # input);

    let behind = parseComments(postParts.post);
    if (behind.rest != "") return #err("Text after email");

    let domainParts = parseDomain(postParts.domain);

    if (not validateDomain(domainParts.domain)) return #err("Invalid domain name: " # domainParts.domain);
    let domain = domainParts.domain;

    let comments = Array.flatten([
      displayParts.comments,
      localParts.comments,
      domainParts.comments,
      behind.comments,
    ]);

    //print(debug_show ("parts", comments));

    //print(debug_show ("debug", preParts.local, localParts.local, validateLocal(localParts.local)));
    return #ok({ comments; raw = input; displayName; local; domain });
  };

  /// Parse a string containing multiple email addreses separated by comma
  public func parseMultiple(input : Text) : Iter.Iter<Result<Email>> {
    Utils.splitOnUnquotedChar(input, ',')
    |> Iter.map(_, parse);
  };

  /// Get the email address without comments or display name
  public func toAddress(email : Email) : Text {
    return email.local # "@" # email.domain;
  };

  /// Get the full email address including display name and comments
  /// All comments will be added to the end of the address
  public func toText(email : Email) : Text {
    let comments = if (email.comments.size() == 0) {
      "";
    } else {
      " " # Text.join(" ", email.comments.vals());
    };
    if (email.displayName != "") {
      return email.displayName # " <" # email.local # "@" # email.domain # ">" # comments;
    };

    return email.local # "@" # email.domain # comments;
  };

};
