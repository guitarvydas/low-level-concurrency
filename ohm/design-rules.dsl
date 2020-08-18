design rules
  all method.phase member(program.phase)
  all field.type member(program.type)
  all method.parameters member(program.type)
  method.return-type member(program.type)
  set(struct.fields)

  all class-name member(program.class)
  script definition in classs.script
  !!! formals of scripts match formals of class
  !!! return-type of scripts match return-type of class
  !!! all exit-whens are inside loop-statement
  !!! all callable-statement are callable

  !!! no duplicate type names
  !!! no duplicate phase names
  
  !!! all ReturnTypeReferences are members of program.type
  !!! all StructNames are unique

  !!! types
  !!! all TypeReference is member(types)
  !!! all AggregateReference is member(types)
end design rules

