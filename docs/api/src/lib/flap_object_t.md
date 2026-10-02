---
title: flap_object_t
---

# flap_object_t

> Base (abstract) class upon which FLAP's concrete classes are built.

**Source**: `src/lib/flap_object_t.F90`

**Dependencies**

```mermaid
graph LR
  flap_object_t["flap_object_t"] --> face["face"]
  flap_object_t["flap_object_t"] --> flap_utils_m["flap_utils_m"]
  flap_object_t["flap_object_t"] --> iso_fortran_env["iso_fortran_env"]
  flap_object_t["flap_object_t"] --> penf["penf"]
```

## Contents

- [object](#object)
- [free_object](#free-object)
- [print_version](#print-version)
- [print_error_message](#print-error-message)
- [set_examples](#set-examples)
- [inherit_error](#inherit-error)
- [clear_error](#clear-error)
- [assign_object](#assign-object)
- [error_prefix](#error-prefix)

## Derived Types

### object

Base (abstract) class upon which FLAP's concrete classes are built.

**Inheritance**

```mermaid
classDiagram
  object <|-- command_line_argument
  object <|-- command_line_arguments_group
  object <|-- command_line_interface
```

**Attributes**: abstract

#### Components

| Name | Type | Attributes | Description |
|------|------|------------|-------------|
| `progname` | character(len=:) | allocatable | Program name. |
| `version` | character(len=:) | allocatable | Program version. |
| `help` | character(len=:) | allocatable | Help message. |
| `help_color` | character(len=:) | allocatable | ANSI color of help messages. |
| `help_style` | character(len=:) | allocatable | ANSI style of help messages. |
| `help_markdown` | character(len=:) | allocatable | Longer help message, markdown formatted. |
| `description` | character(len=:) | allocatable | Detailed description. |
| `license` | character(len=:) | allocatable | License description. |
| `authors` | character(len=:) | allocatable | Authors list. |
| `epilog` | character(len=:) | allocatable | Epilogue message. |
| `m_exclude` | character(len=:) | allocatable | Mutually exclude other CLA(s group). |
| `error_message` | character(len=:) | allocatable | Meaningful error message to standard-error. |
| `error_color` | character(len=:) | allocatable | ANSI color of error messages. |
| `error_style` | character(len=:) | allocatable | ANSI style of error messages. |
| `examples` | type([flap_string](/api/src/lib/flap_utils_m#flap-string)) | allocatable | Examples of correct usage (examples(i)%s). |
| `error` | integer(kind=[I4P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) |  | Error trapping flag. |
| `usage_lun` | integer(kind=[I4P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) |  | Output unit to print help/usage messages |
| `version_lun` | integer(kind=[I4P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) |  | Output unit to print version message |
| `error_lun` | integer(kind=[I4P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) |  | Error unit to print error messages |
| `case_insensitive` | logical |  | Match switches and command names in any case (F14). |

#### Type-Bound Procedures

| Name | Attributes | Description |
|------|------------|-------------|
| `error_prefix` | pass(self) | Prefix of error messages. |
| `free_object` | pass(self) | Free dynamic memory. |
| `print_version` | pass(self) | Print version. |
| `print_error_message` | pass(self) | Print meaningful error message. |
| `inherit_error` | pass(self) | Take the error of another object, with its message. |
| `clear_error` | pass(self) | Forget the error and its message. |
| `set_examples` | pass(self) | Set examples of correct usage. |
| `assign_object` | pass(lhs ) | Assignment overloading. |

## Subroutines

### free_object

Free dynamic memory.

**Attributes**: elemental

```fortran
subroutine free_object(self)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([object](/api/src/lib/flap_object_t#object)) | inout |  | Object data. |

**Call graph**

```mermaid
flowchart TD
  free["free"] --> free_object["free_object"]
  free["free"] --> free_object["free_object"]
  free["free"] --> free_object["free_object"]
  style free_object fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### print_version

Print version.

```fortran
subroutine print_version(self, pref)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([object](/api/src/lib/flap_object_t#object)) | in |  | Object data. |
| `pref` | character(len=*) | in | optional | Prefixing string. |

**Call graph**

```mermaid
flowchart TD
  dispatch_status["dispatch_status"] --> print_version["print_version"]
  style print_version fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### print_error_message

Print meaningful error message to standard-error.

```fortran
subroutine print_error_message(self)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([object](/api/src/lib/flap_object_t#object)) | in |  | Object data. |

**Call graph**

```mermaid
flowchart TD
  errored["errored"] --> print_error_message["print_error_message"]
  errored["errored"] --> print_error_message["print_error_message"]
  errored["errored"] --> print_error_message["print_error_message"]
  get_map_value["get_map_value"] --> print_error_message["print_error_message"]
  raise_error["raise_error"] --> print_error_message["print_error_message"]
  style print_error_message fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### set_examples

Set the examples of correct usage: exactly the given ones, or none.

```fortran
subroutine set_examples(self, examples)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([object](/api/src/lib/flap_object_t#object)) | inout |  | Object data. |
| `examples` | character(len=*) | in | optional | Examples of correct usage. |

**Call graph**

```mermaid
flowchart TD
  add_group["add_group"] --> set_examples["set_examples"]
  init["init"] --> set_examples["set_examples"]
  style set_examples fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### inherit_error

Take the error of another object, with its message: the error of an argument is reported by its group, the one of a
 group by the CLI, whose `error_message` is then the message of its `error`. A status (not positive) has no message.

**Attributes**: pure

```fortran
subroutine inherit_error(self, from)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([object](/api/src/lib/flap_object_t#object)) | inout |  | Object data. |
| `from` | class([object](/api/src/lib/flap_object_t#object)) | in |  | Object that raised the error. |

**Call graph**

```mermaid
flowchart TD
  add["add"] --> inherit_error["inherit_error"]
  check["check"] --> inherit_error["inherit_error"]
  check_m_exclusive["check_m_exclusive"] --> inherit_error["inherit_error"]
  check_m_exclusive["check_m_exclusive"] --> inherit_error["inherit_error"]
  check_maps["check_maps"] --> inherit_error["inherit_error"]
  copy_options["copy_options"] --> inherit_error["inherit_error"]
  get_cla["get_cla"] --> inherit_error["inherit_error"]
  get_cla_list["get_cla_list"] --> inherit_error["inherit_error"]
  get_cla_list_varying_I1P["get_cla_list_varying_I1P"] --> inherit_error["inherit_error"]
  get_cla_list_varying_I2P["get_cla_list_varying_I2P"] --> inherit_error["inherit_error"]
  get_cla_list_varying_I4P["get_cla_list_varying_I4P"] --> inherit_error["inherit_error"]
  get_cla_list_varying_I8P["get_cla_list_varying_I8P"] --> inherit_error["inherit_error"]
  get_cla_list_varying_R16P["get_cla_list_varying_R16P"] --> inherit_error["inherit_error"]
  get_cla_list_varying_R4P["get_cla_list_varying_R4P"] --> inherit_error["inherit_error"]
  get_cla_list_varying_R8P["get_cla_list_varying_R8P"] --> inherit_error["inherit_error"]
  get_cla_list_varying_char["get_cla_list_varying_char"] --> inherit_error["inherit_error"]
  get_cla_list_varying_logical["get_cla_list_varying_logical"] --> inherit_error["inherit_error"]
  get_map["get_map"] --> inherit_error["inherit_error"]
  get_map_value["get_map_value"] --> inherit_error["inherit_error"]
  is_required_passed["is_required_passed"] --> inherit_error["inherit_error"]
  parse["parse"] --> inherit_error["inherit_error"]
  parse_core["parse_core"] --> inherit_error["inherit_error"]
  resolve_values["resolve_values"] --> inherit_error["inherit_error"]
  set_mutually_exclusive_switches["set_mutually_exclusive_switches"] --> inherit_error["inherit_error"]
  style inherit_error fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### clear_error

Forget the error and its message.

**Attributes**: pure

```fortran
subroutine clear_error(self)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([object](/api/src/lib/flap_object_t#object)) | inout |  | Object data. |

**Call graph**

```mermaid
flowchart TD
  add["add"] --> clear_error["clear_error"]
  add_group["add_group"] --> clear_error["clear_error"]
  copy_options["copy_options"] --> clear_error["clear_error"]
  get_cla["get_cla"] --> clear_error["clear_error"]
  get_cla_list["get_cla_list"] --> clear_error["clear_error"]
  get_cla_list_varying_I1P["get_cla_list_varying_I1P"] --> clear_error["clear_error"]
  get_cla_list_varying_I2P["get_cla_list_varying_I2P"] --> clear_error["clear_error"]
  get_cla_list_varying_I4P["get_cla_list_varying_I4P"] --> clear_error["clear_error"]
  get_cla_list_varying_I8P["get_cla_list_varying_I8P"] --> clear_error["clear_error"]
  get_cla_list_varying_R16P["get_cla_list_varying_R16P"] --> clear_error["clear_error"]
  get_cla_list_varying_R4P["get_cla_list_varying_R4P"] --> clear_error["clear_error"]
  get_cla_list_varying_R8P["get_cla_list_varying_R8P"] --> clear_error["clear_error"]
  get_cla_list_varying_char["get_cla_list_varying_char"] --> clear_error["clear_error"]
  get_cla_list_varying_logical["get_cla_list_varying_logical"] --> clear_error["clear_error"]
  get_source["get_source"] --> clear_error["clear_error"]
  map_cla["map_cla"] --> clear_error["clear_error"]
  reset_parse["reset_parse"] --> clear_error["clear_error"]
  reset_parse["reset_parse"] --> clear_error["clear_error"]
  style clear_error fill:#3e63dd,stroke:#99b,stroke-width:2px
```

### assign_object

Assign two abstract objects.

**Attributes**: elemental

```fortran
subroutine assign_object(lhs, rhs)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `lhs` | class([object](/api/src/lib/flap_object_t#object)) | inout |  | Left hand side. |
| `rhs` | class([object](/api/src/lib/flap_object_t#object)) | in |  | Rigth hand side. |

**Call graph**

```mermaid
flowchart TD
  add["add"] --> assign_object["assign_object"]
  add_group["add_group"] --> assign_object["assign_object"]
  init["init"] --> assign_object["assign_object"]
  parse["parse"] --> assign_object["assign_object"]
  style assign_object fill:#3e63dd,stroke:#99b,stroke-width:2px
```

## Functions

### error_prefix

Return the prefix of every error message: the prefixing string, the program name and a (colorized) "error".

**Returns**: `character(len=:)`

```fortran
function error_prefix(self, pref) result(prefd)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `self` | class([object](/api/src/lib/flap_object_t#object)) | in |  | Object data. |
| `pref` | character(len=*) | in | optional | Prefixing string. |

**Call graph**

```mermaid
flowchart TD
  errored["errored"] --> error_prefix["error_prefix"]
  errored["errored"] --> error_prefix["error_prefix"]
  errored["errored"] --> error_prefix["error_prefix"]
  get_map_value["get_map_value"] --> error_prefix["error_prefix"]
  raise_error["raise_error"] --> error_prefix["error_prefix"]
  error_prefix["error_prefix"] --> colorize["colorize"]
  style error_prefix fill:#3e63dd,stroke:#99b,stroke-width:2px
```
