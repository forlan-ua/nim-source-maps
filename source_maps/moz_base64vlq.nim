import moz_base64

# A single base 64 digit can contain 6 bits of data. For the base 64 variable
# length quantities we use in the source map spec, the first bit is the sign,
# the next four bits are the actual value, and the 6th bit is the
# continuation bit. The continuation bit tells us whether there are more
# digits in this value following this digit.
#
#   Continuation
#    |    Sign
#    |    |
#    V    V
#    101011

const VLQ_BASE_SHIFT = 5;

# binary: 100000
const VLQ_BASE = 1 shl VLQ_BASE_SHIFT;

# binary: 011111
const VLQ_BASE_MASK = VLQ_BASE - 1;

# binary: 100000
const VLQ_CONTINUATION_BIT = VLQ_BASE;



# Converts from a two-complement value to a value where the sign bit is
# placed in the least significant bit.  For example, as decimals:
#   1 becomes 2 (10 binary), -1 becomes 3 (11 binary)
#   2 becomes 4 (100 binary), -2 becomes 5 (101 binary)
proc toVLQSigned(aValue: int): int =
  return if aValue < 0: ((-aValue) shl 1) + 1 else: (aValue shl 1) + 0


# Converts to a two-complement value from a value where the sign bit is
# placed in the least significant bit.  For example, as decimals:
#   2 (10 binary) becomes 1, 3 (11 binary) becomes -1
#   4 (100 binary) becomes 2, 5 (101 binary) becomes -2
proc fromVLQSigned(aValue: int): int =
  let isNegative = (aValue and 1) == 1
  let shifted = aValue shr 1
  return if isNegative: -shifted else: shifted


proc decode*(str: string, index: int): array[2, int] =
    var aIndex = index
    var aResult = 0
    var strLen = str.len
    var shift = 0
    var digit: int8
    var continuation = true

    while continuation:
      if aIndex >= strLen:
          raise newException(ValueError, "Expected more digits in base 64 VLQ value.")

      digit = moz_base64.decode(int8(str[aIndex]))
      if digit == -1:
          raise newException(ValueError, "Invalid base64 digit: " & str[aIndex])
      aIndex.inc

      continuation = (digit and VLQ_CONTINUATION_BIT) != 0
      digit = digit and VLQ_BASE_MASK
      aResult = aResult + (int(digit) shl shift)
      shift = shift + VLQ_BASE_SHIFT

    return [fromVLQSigned(aResult), aIndex]
