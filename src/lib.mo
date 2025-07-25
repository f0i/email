import Utils "utils";
import Iter "mo:new-base/Iter";
import Debug "mo:new-base/Debug";
import { print } "mo:new-base/Debug";
import Runtime "mo:new-base/Runtime";
import Result "mo:new-base/Result";
import Array "mo:new-base/Array";
import Text "mo:new-base/Text";
import Array "mo:new-base/Array";
import { splitPre; splitPost; parseLocal; parseComments; parseDomain } "utils";
import { validateLocal; validateDisplay; validateDomain } "validate";

module {
  // This comment will not be included in the documentation
  // Use triple slash for documentation

  public type Email = {
    comments : [Text];
    raw : Text;
    local : Text;
    domain : Text;
    displayName : Text;
  };
  public type Result<T> = Result.Result<T, Text>;

  public func parseOne(input : Text) : Result<Email> {
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

  public func parse(input : Text) : Iter.Iter<Result<Email>> {
    Utils.splitOnUnquotedChar(input, ',')
    |> Iter.map(_, parseOne);
  };

  public func toAddress(email : Email) : Text {
    return email.local # "@" # email.domain;
  };

  public func toText(email : Email) : Text {
    let comments = if (comments.size() == 0) {
      "";
    } else {
      " " # Text.join(" ", Array.vals(comments));
    };
    if (email.displayName != "") {
      return email.displayName # " <" # email.local # "@" # email.domain # ">";
    };

    return email.local # "@" # email.domain;
  };

};
