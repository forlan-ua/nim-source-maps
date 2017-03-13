const intToCharMap* = [
    'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S',
    'T','U','V','W','X','Y','Z','a','b','c','d','e','f','g','h','i','j','k','l',
    'm','n','o','p','q','r','s','t','u','v','w','x','y','z','0','1','2','3','4',
    '5','6','7','8','9','+','/'
]

# Encode an integer in the range of 0 to 63 to a single base 64 .
proc encode*(number: int8): char =
  if number >= 0 and number <= 63:
    return intToCharMap[number]
  raise newException(ValueError, "Must be between 0 and 63: " & $number)


const bigA: int8 = 65;     # 'A'
const bigZ: int8 = 90;     # 'Z'

const littleA: int8 = 97;  # 'a'
const littleZ: int8 = 122; # 'z'

const zero: int8 = 48;     # '0'
const nine: int8 = 57;     # '9'

const plus: int8 = 43;     # '+'
const slash: int8 = 47;    # '/'

const littleOffset: int8 = 26;
const numberOffset: int8 = 52;


# Decode a single base 64 character code digit to an integer. Returns -1 on
# failure.
proc decode*(charCode: int8): int8 =
  # 0 - 25: ABCDEFGHIJKLMNOPQRSTUVWXYZ
  if bigA <= charCode and charCode <= bigZ:
    return charCode - bigA

  # 26 - 51: abcdefghijklmnopqrstuvwxyz
  if littleA <= charCode and charCode <= littleZ:
    return charCode - littleA + littleOffset

  # 52 - 61: 0123456789
  if zero <= charCode and charCode <= nine:
    return charCode - zero + numberOffset

  # 62: +
  if charCode == plus:
    return 62

  # 63: /
  if charCode == slash:
    return 63

  # Invalid base64 digit.
  return -1;
