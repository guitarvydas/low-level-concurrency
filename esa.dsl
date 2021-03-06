
type name
type function
type boolean
type node-class
type value

phase building
phase building-aux
phase loading
phase initializing
phase running

struct part-definition
  part-name
  part-kind
end struct

struct named-part-instance
  instance-name
  instance-node
end struct

struct part-pin
  part-name
  pin-name
end struct

struct source
  part-name  % a name or "self"
  pin-name
end struct

struct destination
  part-name
  pin-name
end struct

struct wire
  index
  map sources
  map destinations
end struct

struct kind
  kind-name
  input-pins
  self-struct  % of type node-struct % subsumes initially code, react code and instance vars (using OO), otherwise OO is overkill
  output-pins
  parts
  wires
end struct

struct node
  input-queue
  output-queue
  kind-field
  container
  name-in-container  %% lookup this part instance by name as a child of my container
  children
  busy-flag
end struct

struct dispatcher
  list all-parts
  top-node
end struct

struct event
  partpin
  data
end struct

%=== building kinds ===

when building kind
  external-method install-input-pin(name)
  external-method install-output-pin(name)
  script add-input-pin(name)
  script add-output-pin(name)
  % external-method install-initially-function(function)
  script add-part(name kind node-class)
  script add-wire(wire)
  external-method install-wire(wire)
  external-method install-part(name kind node-class)
  external-method parts >> list part-definition
end when

when building-aux kind
  external-method install-class(node-class)
  external-method ensure-part-not-declared(name)
  external-method ensure-valid-input-pin(name)
  external-method ensure-valid-output-pin(name)
  external-method ensure-input-pin-not-declared(name)
  external-method ensure-output-pin-not-declared(name)
  script ensure-valid-source(source)
  script ensure-valid-destination(destination)
end when

when building part-definition
  external-method ensure-kind-defined	
end when

script kind add-input-pin(name)
   self.ensure-input-pin-not-declared(name)
   self.install-input-pin(name)
end script

script kind add-output-pin(name)
   self.ensure-output-pin-not-declared(name)
   self.install-output-pin(name)
end script

script kind add-part(nm k nclass)
  self.ensure-part-not-declared(nm)
  self.install-part(nm k nclass)
end script

script kind add-wire(w)
  % self is a container ==> sources and all dests must be contained as children, or, refer to "self"
  for s = w.sources in
    @self.ensure-valid-source(s)
  end for
  for dest = w.destinations in
    @self.ensure-valid-destination(dest)
  end for
  self.install-wire(w)
end script

script kind ensure-valid-source(s)
  if s.refers-to-self? then
    self.ensure-valid-input-pin(s.pin-name)
  else
    let p = self.kind-find-part(s.part-name) in
      p.ensure-kind-defined
      p.part-kind.ensure-valid-output-pin(s.pin-name)
    end let
  end if
end script

script kind ensure-valid-destination(dest)
  if dest.refers-to-self? then
    self.ensure-valid-output-pin(dest.pin-name)
  else
    let p = self.kind-find-part(dest.part-name) in
      p.ensure-kind-defined
      p.part-kind.ensure-valid-input-pin(dest.pin-name)
    end let
  end if
end script

%=== building wires ===

when building source
  external-method refers-to-self? >> boolean %% true if self.part-name == "self"
end when

when building destination 
  external-method refers-to-self? >> boolean %% true if self.part-name == "self"
end when

when building wire
  external-method install-source(name name)
  external-method install-destination(name name)
  script add-source(name name)
  script add-destination(name name)
end when

script wire add-source(part pin)
  self.install-source(part pin)
end script

script wire add-destination(part pin)
  self.install-destination(part pin)
end script


%=== instantiating parts ===

when loading kind
%                    node=runtime-container
%                    |
%                    V
  script loader(name node dispatcher) >> node
end when

when loading node
  external-method clear-input-queue
  external-method clear-output-queue
  external-method install-node(node)
  script add-child(name node)
  % external-method children >> list named-part-instance
end when

script kind loader(my-name my-container dispatchr) >> node  % return an object that inherits from node
  let clss = self.self-class in
    create inst = *clss in
      inst.clear-input-queue
      inst.clear-output-queue
      set inst.kind-field = self
      set inst.container = my-container
      set inst.name-in-container = my-name
      for part = self.parts in  % for over kind.parts
	let part-instance = @part.part-kind.loader(part.part-name inst dispatchr) in
	  @inst.add-child(part.part-name part-instance)
	end let
      end for
      dispatchr.memo-node(inst)
      >> inst
    end create
  end let
end script

when loading dispatcher
  external-method memo-node(node)
  external-method set-top-node(node)
end when

script node add-child(nm nd)
  self.install-child(nm nd)
end script
%=== initializing ===

when initializing dispatcher
  script initialize-all
end when

script dispatcher initialize-all
  for part = self.all-parts in
    @part.initialize
  end for
end script

when initializing node
  script initialize
  external-method initially  % can call SEND, but distribution of events deferred until running
end when

script node initialize
  self.initially
end script

%=== overlapping external-methods ===

when intializing or running node
  external-method send(event)
  script distribute-output-events
  external-method display-output-events-to-console-and-delete
  external-method get-output-events-and-delete >> list event
  external-method has-no-container? >> boolean
  script distribute-outputs-upwards
end when

%=== running ===

when running dispatcher
  script distribute-all-outputs
  script dispatcher-run
  script dispatcher-inject
  external-method create-top-event(name value) >> event
end when

when running kind
  external-method find-wire-for-source(name name) >> wire
  external-method find-wire-for-self-source(name) >> wire
end when

when running node
  script busy?
  script ready?
  script invoke
  external-method has-inputs-or-outputs? >> boolean
  external-method children? >> boolean
  external-method flagged-as-busy? >> boolean
  external-method dequeue-input
  external-method input-queue?
  external-method enqueue-input(event)
  external-method enqueue-output(event)
  external-method react(event)
  script run-reaction(event)
  script run-composite-reaction(event)
  external-method node-find-child(name) >> named-part-instance
end when

script node busy? >> boolean
  % atomically
  if self.flagged-as-busy? then
    >> true
  else
    for child-part-instance = self.children in
      let child-node = child-part-instance.instance-node in
	if child-node.has-inputs-or-outputs? then
	  >> true
	else
	  if @child-node.busy? then
	    >> true
	  end if
	end if
      end let
    end for
  end if
  >> false
  % end atomically
end script

script dispatcher dispatcher-run
  let done = true in
    loop
      set done = true
      @self.distribute-all-outputs
      for part = self.all-parts in
        if @part.ready? then
          @part.invoke
          set done = false
          exit-for
        end if
      end for
      exit-when done
    end loop
  end let
end script

script dispatcher dispatcher-inject(pin val)
  let e = self.create-top-event(pin val) in
    self.top-node.enqueue-input(e)
    @self.dispatcher-run
  end let
end script

script node invoke
  let e = self.dequeue-input in
    @self.run-reaction(e)
    @self.distribute-output-events
  end let
end script

script node ready? >> boolean
  % atomically
    if self.input-queue? then
      if @self.busy? then
        >> false
      else
        >> true
      end if
    end if
    >> false
  % end atomically
end script

script dispatcher distribute-all-outputs
  for p = self.all-parts in
    @p.distribute-output-events
    @p.distribute-outputs-upwards
  end for
end script

script node distribute-outputs-upwards
  % if node create an output event on the parent, then distribute parent's output
  if self.has-no-container? then  
    %% stops upward recursion at top node (no container)
  else
    let parent = self.container in
      @parent.distribute-output-events
    end let
  end if 
end script

script node distribute-output-events
  % an output event can be delivered to three possible places
  % 1. a child (part/pin) [most common]
  % 2. the parent's output pin ("self"/pin)
  % 3. the console if this is the top part (no container)

  if self.has-no-container? then
    % case 3.
    self.display-output-events-to-console-and-delete
  else
    let parent-composite-node = self.container in
       for output = self.get-output-events-and-delete in
         let dest = output.partpin in
           let w = parent-composite-node.kind-field.find-wire-for-source(output.partpin.part-name output.partpin.pin-name) in
             for dest = w.destinations in
               if dest.refers-to-self? then
                 % case 2
                 create new-event = event in
                   create pp = part-pin in
                     set pp.part-name = parent-composite-node.name-in-container
                     set pp.pin-name = dest.pin-name
                     set new-event.partpin = pp
                     set new-event.data = output.data
                     parent-composite-node.send(new-event)
                   end create
                 end create
               else
                 % case 1 - the common case - child outputs to input of another child
                 create new-event = event in
                   create pp = part-pin in
                     set pp.part-name = dest.part-name
                     set pp.pin-name = dest.pin-name
                     set new-event.partpin = pp
                     set new-event.data = output.data
                     let child-part-instance = parent-composite-node.node-find-child(pp.part-name) in
                       child-part-instance.instance-node.enqueue-input(new-event)
                     end let
                   end create
                 end create
               end if
             end for
           end let
         end let
       end for
    end let
  end if
end script

script node run-reaction(e)  % composite reaction
  self.react(e)
end script

script node run-composite-reaction(e)
  % composites distribute their inputs to 
  % 1. children [most common], or,
  % 2. to self.output(s) as appropriate

  let w = true in
    if self.has-no-container? then
      set w = self.kind-field.find-wire-for-self-source(e.partpin.pin-name)
    else	
      set w = self.container.kind-field.find-wire-for-source(e.partpin.part-name e.partpin.pin-name)
    end if
    for dest = w.destinations in
      create new-event = event in
	create pp = part-pin in
          if dest.refers-to-self? then
              % self.in going to out must go to an output pin
              % this has already been checked during build
              set pp.part-name = dest.part-name %"self"
              set pp.pin-name = dest.pin-name
              set new-event.partpin = pp
              set new-event.data = e.data
              self.send(new-event)
          else
            % else, must go to an input of a child
            if self.children? then
              set pp.part-name = dest.part-name
              set pp.pin-name = dest.pin-name
              set new-event.partpin = pp
              set new-event.data = e.data
              let child-part-instance = self.node-find-child(dest.part-name) in
                child-part-instance.instance-node.enqueue-input(new-event)
              end let
             end if
          end if
	end create
      end create
    end for
  end let
end script

