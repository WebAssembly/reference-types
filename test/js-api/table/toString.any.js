// META: global=jsshell

test(() => {
  const argument = { "element": "funcref", "initial": 0 };
  const table = new WebAssembly.Table(argument);
  assert_class_string(table, "WebAssembly.Table");
}, "Object.prototype.toString on an Table");
