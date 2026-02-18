---
title: penf_global_parameters_variables
---

# penf_global_parameters_variables

> PENF global parameters and variables.

 @note All module defined entities are public.

**Source**: `src/third_party/PENF/src/lib/penf_global_parameters_variables.F90`

## Variables

| Name | Type | Attributes | Description |
|------|------|------------|-------------|
| `endianL` | integer | parameter | Little endian parameter. |
| `endianB` | integer | parameter | Big endian parameter. |
| `ASCII` | integer | parameter | ASCII character set kind defined as default set. |
| `UCS4` | integer | parameter | Unicode character set kind defined as default set. |
| `CK` | integer | parameter | Default kind character. |
| `R16P` | integer | parameter | 15 digits, range \([10^{-307} , 10^{+307}  - 1]\); 64 bits. |
| `R8P` | integer | parameter | 15 digits, range \([10^{-307} , 10^{+307}  - 1]\); 64 bits. |
| `R4P` | integer | parameter | 6  digits, range \([10^{-37}  , 10^{+37}   - 1]\); 32 bits. |
| `R_P` | integer | parameter | Default real precision. |
| `I8P` | integer | parameter | Range \([-2^{63},+2^{63} - 1]\), 19 digits plus sign; 64 bits. |
| `I4P` | integer | parameter | Range \([-2^{31},+2^{31} - 1]\), 10 digits plus sign; 32 bits. |
| `I2P` | integer | parameter | Range \([-2^{15},+2^{15} - 1]\), 5  digits plus sign; 16 bits. |
| `I1P` | integer | parameter | Range \([-2^{7} ,+2^{7}  - 1]\), 3  digits plus sign; 8  bits. |
| `I_P` | integer | parameter | Default integer precision. |
| `FR16P` | character(len=*) | parameter | Output format for kind=R8P real. |
| `FR8P` | character(len=*) | parameter | Output format for kind=R8P real. |
| `FR4P` | character(len=*) | parameter | Output format for kind=R4P real. |
| `FR_P` | character(len=*) | parameter | Output format for kind=R_P real. |
| `FI8P` | character(len=*) | parameter | Output format for kind=I8P integer. |
| `FI8PZP` | character(len=*) | parameter | Output format for kind=I8P integer with zero prefixing. |
| `FI4P` | character(len=*) | parameter | Output format for kind=I4P integer. |
| `FI4PZP` | character(len=*) | parameter | Output format for kind=I4P integer with zero prefixing. |
| `FI2P` | character(len=*) | parameter | Output format for kind=I2P integer. |
| `FI2PZP` | character(len=*) | parameter | Output format for kind=I2P integer with zero prefixing. |
| `FI1P` | character(len=*) | parameter | Output format for kind=I1P integer. |
| `FI1PZP` | character(len=*) | parameter | Output format for kind=I1P integer with zero prefixing. |
| `FI_P` | character(len=*) | parameter | Output format for kind=I_P integer. |
| `FI_PZP` | character(len=*) | parameter | Output format for kind=I_P integer with zero prefixing. |
| `DR16P` | integer | parameter | Number of digits of output format FR8P. |
| `DR8P` | integer | parameter | Number of digits of output format FR8P. |
| `DR4P` | integer | parameter | Number of digits of output format FR4P. |
| `DR_P` | integer | parameter | Number of digits of output format FR_P. |
| `DI8P` | integer | parameter | Number of digits of output format I8P. |
| `DI4P` | integer | parameter | Number of digits of output format I4P. |
| `DI2P` | integer | parameter | Number of digits of output format I2P. |
| `DI1P` | integer | parameter | Number of digits of output format I1P. |
| `DI_P` | integer | parameter | Number of digits of output format I_P. |
| `CHARACTER_KINDS_LIST` | integer | parameter | List of character kinds. |
| `REAL_KINDS_LIST` | integer | parameter | List of real kinds. |
| `REAL_FORMATS_LIST` | character(len=*) | parameter | List of real formats. |
| `INTEGER_KINDS_LIST` | integer | parameter | List of integer kinds. |
| `INTEGER_FORMATS_LIST` | character(len=*) | parameter | List of integer formats. |
| `MinR16P` | real(kind=[R8P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Minimum value of kind=R8P real. |
| `MaxR16P` | real(kind=[R8P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Maximum value of kind=R8P real. |
| `MinR8P` | real(kind=[R8P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Minimum value of kind=R8P real. |
| `MaxR8P` | real(kind=[R8P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Maximum value of kind=R8P real. |
| `MinR4P` | real(kind=[R4P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Minimum value of kind=R4P real. |
| `MaxR4P` | real(kind=[R4P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Maximum value of kind=R4P real. |
| `MinR_P` | real(kind=[R_P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Minimum value of kind=R_P real. |
| `MaxR_P` | real(kind=[R_P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Maximum value of kind=R_P real. |
| `MinI8P` | integer(kind=[I8P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Minimum value of kind=I8P integer. |
| `MinI4P` | integer(kind=[I4P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Minimum value of kind=I4P integer. |
| `MinI2P` | integer(kind=[I2P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Minimum value of kind=I2P integer. |
| `MinI1P` | integer(kind=[I1P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Minimum value of kind=I1P integer. |
| `MinI_P` | integer(kind=[I_P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Minimum value of kind=I_P integer. |
| `MaxI8P` | integer(kind=[I8P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Maximum value of kind=I8P integer. |
| `MaxI4P` | integer(kind=[I4P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Maximum value of kind=I4P integer. |
| `MaxI2P` | integer(kind=[I2P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Maximum value of kind=I2P integer. |
| `MaxI1P` | integer(kind=[I1P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Maximum value of kind=I1P integer. |
| `MaxI_P` | integer(kind=[I_P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Maximum value of kind=I_P integer. |
| `smallR16P` | real(kind=[R8P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Smallest representable value of kind=R8P real. |
| `smallR8P` | real(kind=[R8P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Smallest representable value of kind=R8P real. |
| `smallR4P` | real(kind=[R4P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Smallest representable value of kind=R4P real. |
| `smallR_P` | real(kind=[R_P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Smallest representable value of kind=R_P real. |
| `ZeroR16P` | real(kind=[R8P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter |  |
| `ZeroR8P` | real(kind=[R8P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter |  |
| `ZeroR4P` | real(kind=[R4P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter |  |
| `ZeroR_P` | real(kind=[R_P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter |  |
| `BIR16P` | integer(kind=[I1P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Number of bits of kind=R8P real. |
| `BIR8P` | integer(kind=[I1P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Number of bits of kind=R8P real. |
| `BIR4P` | integer(kind=[I1P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Number of bits of kind=R4P real. |
| `BIR_P` | integer(kind=[I1P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Number of bits of kind=R_P real. |
| `BYR16P` | integer(kind=[I1P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Number of bytes of kind=R8P real. |
| `BYR8P` | integer(kind=[I1P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Number of bytes of kind=R8P real. |
| `BYR4P` | integer(kind=[I1P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Number of bytes of kind=R4P real. |
| `BYR_P` | integer(kind=[I1P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Number of bytes of kind=R_P real. |
| `BII8P` | integer(kind=[I8P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Number of bits of kind=I8P integer. |
| `BII4P` | integer(kind=[I4P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Number of bits of kind=I4P integer. |
| `BII2P` | integer(kind=[I2P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Number of bits of kind=I2P integer. |
| `BII1P` | integer(kind=[I1P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Number of bits of kind=I1P integer. |
| `BII_P` | integer(kind=[I_P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Number of bits of kind=I_P integer. |
| `BYI8P` | integer(kind=[I8P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Number of bytes of kind=I8P integer. |
| `BYI4P` | integer(kind=[I4P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Number of bytes of kind=I4P integer. |
| `BYI2P` | integer(kind=[I2P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Number of bytes of kind=I2P integer. |
| `BYI1P` | integer(kind=[I1P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Number of bytes of kind=I1P integer. |
| `BYI_P` | integer(kind=[I_P](/api/src/third_party/PENF/src/lib/penf_global_parameters_variables)) | parameter | Number of bytes of kind=I_P integer. |
