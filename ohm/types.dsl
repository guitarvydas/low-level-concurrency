types
  program = { [type] [phase] [class] }
    type == type-name
    phase == phase-name
    class = { struct [method] }

      struct = { [field]) }
        field == type

      method =| external-method | script

         external-method = { phase method-name [formal] return-type}
         script =          { phase script-name [formal] return-type implementation }

  
  implementation == [statement]

  type-name == name
  phase-name == name
  struct-name == name
  field-name == name
  var == name
  name == :string

  expression = { expression-kind object }
    expression-kind = 'true' | 'false' | 'object'
    object = { object-name [field] }
      field = { field-name field-kind [actual-parameter]
      field-name == name
      field-kind = 'simple' | 'collection'
      actual-parameter == expression

  statement = | let-statement | set-statement | create-statement
              | for-statement | loop-statement | exit-when-statement 
	      | if-statement
              | call-internal-statement | call-external-statement
  let-statement = { var expression body }
  set-statement = { var expression body }
  create-statement = { var class-ref body }
  for-statement = { var list-ref body } 
  loop-statement = { body }
  exit-when-statement = { boolean-expression }
  if-statement = { boolean-expression then-body else-body }
  call-internal-statement = { callable-expression }
  call-external-statement = { callable-expression }

  boolean-expression == expression
  then-body == implementation
  else-body == implementation
  list-ref == expression
  class-ref == expression
  callable-expression == expression
  body == implementation
    
end types
