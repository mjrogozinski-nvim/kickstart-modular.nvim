; extends

(namespace_identifier) @namespace.inner

; Keep namespace textobjects whitespace-free. The outer object is exactly the
; namespace segment plus its following separator, e.g. "ns::".
(qualified_identifier
  (namespace_identifier) @namespace.outer
  .
  "::" @namespace.outer)

(nested_namespace_specifier
  (namespace_identifier) @namespace.outer
  .
  "::" @namespace.outer)
