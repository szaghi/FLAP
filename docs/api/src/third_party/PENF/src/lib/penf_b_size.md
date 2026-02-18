---
title: penf_b_size
---

# penf_b_size

> PENF bit/byte size functions.

**Source**: `src/third_party/PENF/src/lib/penf_b_size.F90`

**Dependencies**

```mermaid
graph LR
  penf_b_size["penf_b_size"] --> penf_global_parameters_variables["penf_global_parameters_variables"]
```

## Contents

- [bit_size](#bit-size)
- [byte_size](#byte-size)
- [bit_size_R16P](#bit-size-r16p)
- [bit_size_R8P](#bit-size-r8p)
- [bit_size_R4P](#bit-size-r4p)
- [bit_size_chr](#bit-size-chr)
- [byte_size_R16P](#byte-size-r16p)
- [byte_size_R8P](#byte-size-r8p)
- [byte_size_R4P](#byte-size-r4p)
- [byte_size_chr](#byte-size-chr)
- [byte_size_I8P](#byte-size-i8p)
- [byte_size_I4P](#byte-size-i4p)
- [byte_size_I2P](#byte-size-i2p)
- [byte_size_I1P](#byte-size-i1p)

## Interfaces

### bit_size

Overloading of the intrinsic *bit_size* function for computing the number of bits of (also) real and character variables.

**Module procedures**: [`bit_size_R8P`](/api/src/third_party/PENF/src/lib/penf_b_size#bit-size-r8p), [`bit_size_R4P`](/api/src/third_party/PENF/src/lib/penf_b_size#bit-size-r4p), [`bit_size_chr`](/api/src/third_party/PENF/src/lib/penf_b_size#bit-size-chr)

### byte_size

Compute the number of bytes of a variable.

**Module procedures**: [`byte_size_I8P`](/api/src/third_party/PENF/src/lib/penf_b_size#byte-size-i8p), [`byte_size_I4P`](/api/src/third_party/PENF/src/lib/penf_b_size#byte-size-i4p), [`byte_size_I2P`](/api/src/third_party/PENF/src/lib/penf_b_size#byte-size-i2p), [`byte_size_I1P`](/api/src/third_party/PENF/src/lib/penf_b_size#byte-size-i1p), [`byte_size_R8P`](/api/src/third_party/PENF/src/lib/penf_b_size#byte-size-r8p), [`byte_size_R4P`](/api/src/third_party/PENF/src/lib/penf_b_size#byte-size-r4p), [`byte_size_chr`](/api/src/third_party/PENF/src/lib/penf_b_size#byte-size-chr)

## Functions

### bit_size_R16P

Compute the number of bits of a real variable.

```fortran
 use penf
 print FI2P, bit_size(1._R16P)
```

**Attributes**: elemental

**Returns**: integer(kind=[I2P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables))

```fortran
function bit_size_R16P(i) result(bits)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `i` | real(kind=[R16P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | in |  | Real variable whose number of bits must be computed. |

### bit_size_R8P

Compute the number of bits of a real variable.

```fortran
 use penf
 print FI1P, bit_size(1._R8P)
```

**Attributes**: elemental

**Returns**: integer(kind=[I1P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables))

```fortran
function bit_size_R8P(i) result(bits)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `i` | real(kind=[R8P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | in |  | Real variable whose number of bits must be computed. |

### bit_size_R4P

Compute the number of bits of a real variable.

```fortran
 use penf
 print FI1P, bit_size(1._R4P)
```

**Attributes**: elemental

**Returns**: integer(kind=[I1P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables))

```fortran
function bit_size_R4P(i) result(bits)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `i` | real(kind=[R4P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | in |  | Real variable whose number of bits must be computed. |

### bit_size_chr

Compute the number of bits of a character variable.

```fortran
 use penf
 print FI4P, bit_size('ab')
```

**Attributes**: elemental

**Returns**: integer(kind=[I4P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables))

```fortran
function bit_size_chr(i) result(bits)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `i` | character(len=*) | in |  | Character variable whose number of bits must be computed. |

### byte_size_R16P

Compute the number of bytes of a real variable.

```fortran
 use penf
 print FI1P, byte_size(1._R16P)
```

**Attributes**: elemental

**Returns**: integer(kind=[I1P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables))

```fortran
function byte_size_R16P(i) result(bytes)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `i` | real(kind=[R16P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | in |  | Real variable whose number of bytes must be computed. |

### byte_size_R8P

Compute the number of bytes of a real variable.

```fortran
 use penf
 print FI1P, byte_size(1._R8P)
```

**Attributes**: elemental

**Returns**: integer(kind=[I1P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables))

```fortran
function byte_size_R8P(i) result(bytes)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `i` | real(kind=[R8P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | in |  | Real variable whose number of bytes must be computed. |

### byte_size_R4P

Compute the number of bytes of a real variable.

```fortran
 use penf
 print FI1P, byte_size(1._R4P)
```

**Attributes**: elemental

**Returns**: integer(kind=[I1P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables))

```fortran
function byte_size_R4P(i) result(bytes)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `i` | real(kind=[R4P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | in |  | Real variable whose number of bytes must be computed. |

### byte_size_chr

Compute the number of bytes of a character variable.

```fortran
 use penf
 print FI1P, byte_size('ab')
```

**Attributes**: elemental

**Returns**: integer(kind=[I4P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables))

```fortran
function byte_size_chr(i) result(bytes)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `i` | character(len=*) | in |  | Character variable whose number of bytes must be computed. |

### byte_size_I8P

Compute the number of bytes of an integer variable.

```fortran
 use penf
 print FI1P, byte_size(1_I8P)
```

**Attributes**: elemental

**Returns**: integer(kind=[I1P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables))

```fortran
function byte_size_I8P(i) result(bytes)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `i` | integer(kind=[I8P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | in |  | Integer variable whose number of bytes must be computed. |

### byte_size_I4P

Compute the number of bytes of an integer variable.

```fortran
 use penf
 print FI1P, byte_size(1_I4P)
```

**Attributes**: elemental

**Returns**: integer(kind=[I1P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables))

```fortran
function byte_size_I4P(i) result(bytes)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `i` | integer(kind=[I4P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | in |  | Integer variable whose number of bytes must be computed. |

### byte_size_I2P

Compute the number of bytes of an integer variable.

```fortran
 use penf
 print FI1P, byte_size(1_I2P)
```

**Attributes**: elemental

**Returns**: integer(kind=[I1P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables))

```fortran
function byte_size_I2P(i) result(bytes)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `i` | integer(kind=[I2P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | in |  | Integer variable whose number of bytes must be computed. |

### byte_size_I1P

Compute the number of bytes of an integer variable.

```fortran
 use penf
 print FI1P, byte_size(1_I1P)
```

**Attributes**: elemental

**Returns**: integer(kind=[I1P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables))

```fortran
function byte_size_I1P(i) result(bytes)
```

**Arguments**

| Name | Type | Intent | Attributes | Description |
|------|------|--------|------------|-------------|
| `i` | integer(kind=[I1P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | in |  | Integer variable whose number of bytes must be computed. |
