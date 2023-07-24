func animate_property(node_path,property_name,value):
    if node_path == "AnimationPlayer":
        return
    get_node(node_path).set(property_name,value)

func animate_method(method_name,allowed_functions,args):
    if method_name in allowed_functions:
        callv(method_name, args)
    else:
        breakpoint