from main import *
from ......CXX11.Tensor import Tensor, RowMajor, PADDING_VALID, PADDING_SAME

def test_simple_patch() raises:
  var tensor = Tensor[Float32, 4](2, 3, 5, 7)
  tensor.setRandom()
  var tensor_row_major = Tensor[Float32, 4, RowMajor](tensor.swap_layout())
  VERIFY_IS_EQUAL(tensor.dimension(0), tensor_row_major.dimension(3))
  VERIFY_IS_EQUAL(tensor.dimension(1), tensor_row_major.dimension(2))
  VERIFY_IS_EQUAL(tensor.dimension(2), tensor_row_major.dimension(1))
  VERIFY_IS_EQUAL(tensor.dimension(3), tensor_row_major.dimension(0))

  var single_pixel_patch = Tensor[Float32, 5]()
  single_pixel_patch = tensor.extract_image_patches(1, 1)
  VERIFY_IS_EQUAL(single_pixel_patch.dimension(0), 2)
  VERIFY_IS_EQUAL(single_pixel_patch.dimension(1), 1)
  VERIFY_IS_EQUAL(single_pixel_patch.dimension(2), 1)
  VERIFY_IS_EQUAL(single_pixel_patch.dimension(3), 3 * 5)
  VERIFY_IS_EQUAL(single_pixel_patch.dimension(4), 7)

  var single_pixel_patch_row_major = Tensor[Float32, 5, RowMajor]()
  single_pixel_patch_row_major = tensor_row_major.extract_image_patches(1, 1)
  VERIFY_IS_EQUAL(single_pixel_patch_row_major.dimension(0), 7)
  VERIFY_IS_EQUAL(single_pixel_patch_row_major.dimension(1), 3 * 5)
  VERIFY_IS_EQUAL(single_pixel_patch_row_major.dimension(2), 1)
  VERIFY_IS_EQUAL(single_pixel_patch_row_major.dimension(3), 1)
  VERIFY_IS_EQUAL(single_pixel_patch_row_major.dimension(4), 2)

  for i in range(tensor.size()):
    if tensor.data()[i] != single_pixel_patch.data()[i]:
      print("Mismatch detected at index ", i, " : ", tensor.data()[i], " vs ", single_pixel_patch.data()[i])
    VERIFY_IS_EQUAL(single_pixel_patch.data()[i], tensor.data()[i])
    if tensor_row_major.data()[i] != single_pixel_patch_row_major.data()[i]:
      print("Mismatch detected at index ", i, " : ", tensor.data()[i], " vs ", single_pixel_patch_row_major.data()[i])
    VERIFY_IS_EQUAL(single_pixel_patch_row_major.data()[i], tensor_row_major.data()[i])
    VERIFY_IS_EQUAL(tensor.data()[i], tensor_row_major.data()[i])
    VERIFY_IS_EQUAL(single_pixel_patch.data()[i], single_pixel_patch_row_major.data()[i])

  var entire_image_patch = Tensor[Float32, 5]()
  entire_image_patch = tensor.extract_image_patches(3, 5)
  VERIFY_IS_EQUAL(entire_image_patch.dimension(0), 2)
  VERIFY_IS_EQUAL(entire_image_patch.dimension(1), 3)
  VERIFY_IS_EQUAL(entire_image_patch.dimension(2), 5)
  VERIFY_IS_EQUAL(entire_image_patch.dimension(3), 3 * 5)
  VERIFY_IS_EQUAL(entire_image_patch.dimension(4), 7)

  var entire_image_patch_row_major = Tensor[Float32, 5, RowMajor]()
  entire_image_patch_row_major = tensor_row_major.extract_image_patches(3, 5)
  VERIFY_IS_EQUAL(entire_image_patch_row_major.dimension(0), 7)
  VERIFY_IS_EQUAL(entire_image_patch_row_major.dimension(1), 3 * 5)
  VERIFY_IS_EQUAL(entire_image_patch_row_major.dimension(2), 5)
  VERIFY_IS_EQUAL(entire_image_patch_row_major.dimension(3), 3)
  VERIFY_IS_EQUAL(entire_image_patch_row_major.dimension(4), 2)

  for i in range(3):
    for j in range(5):
      var patchId = i + 3 * j
      for r in range(3):
        for c in range(5):
          for d in range(2):
            for b in range(7):
              var expected = 0.0
              var expected_row_major = 0.0
              if r - 1 + i >= 0 and c - 2 + j >= 0 and r - 1 + i < 3 and c - 2 + j < 5:
                expected = tensor(d, r - 1 + i, c - 2 + j, b)
                expected_row_major = tensor_row_major(b, c - 2 + j, r - 1 + i, d)
              if entire_image_patch(d, r, c, patchId, b) != expected:
                print("Mismatch detected at index i=", i, " j=", j, " r=", r, " c=", c, " d=", d, " b=", b)
              VERIFY_IS_EQUAL(entire_image_patch(d, r, c, patchId, b), expected)
              if entire_image_patch_row_major(b, patchId, c, r, d) != expected_row_major:
                print("Mismatch detected at index i=", i, " j=", j, " r=", r, " c=", c, " d=", d, " b=", b)
              VERIFY_IS_EQUAL(entire_image_patch_row_major(b, patchId, c, r, d), expected_row_major)
              VERIFY_IS_EQUAL(expected, expected_row_major)

  var twod_patch = Tensor[Float32, 5]()
  twod_patch = tensor.extract_image_patches(2, 2)
  VERIFY_IS_EQUAL(twod_patch.dimension(0), 2)
  VERIFY_IS_EQUAL(twod_patch.dimension(1), 2)
  VERIFY_IS_EQUAL(twod_patch.dimension(2), 2)
  VERIFY_IS_EQUAL(twod_patch.dimension(3), 3 * 5)
  VERIFY_IS_EQUAL(twod_patch.dimension(4), 7)

  var twod_patch_row_major = Tensor[Float32, 5, RowMajor]()
  twod_patch_row_major = tensor_row_major.extract_image_patches(2, 2)
  VERIFY_IS_EQUAL(twod_patch_row_major.dimension(0), 7)
  VERIFY_IS_EQUAL(twod_patch_row_major.dimension(1), 3 * 5)
  VERIFY_IS_EQUAL(twod_patch_row_major.dimension(2), 2)
  VERIFY_IS_EQUAL(twod_patch_row_major.dimension(3), 2)
  VERIFY_IS_EQUAL(twod_patch_row_major.dimension(4), 2)

  var row_padding: Int = 0
  var col_padding: Int = 0
  var stride: Int = 1
  for i in range(3):
    for j in range(5):
      var patchId = i + 3 * j
      for r in range(2):
        for c in range(2):
          for d in range(2):
            for b in range(7):
              var expected = 0.0
              var expected_row_major = 0.0
              var row_offset = r * stride + i - row_padding
              var col_offset = c * stride + j - col_padding
              if row_offset >= 0 and col_offset >= 0 and row_offset < tensor.dimension(1) and col_offset < tensor.dimension(2):
                expected = tensor(d, row_offset, col_offset, b)
              if twod_patch(d, r, c, patchId, b) != expected:
                print("Mismatch detected at index i=", i, " j=", j, " r=", r, " c=", c, " d=", d, " b=", b)
              VERIFY_IS_EQUAL(twod_patch(d, r, c, patchId, b), expected)
              if row_offset >= 0 and col_offset >= 0 and row_offset < tensor_row_major.dimension(2) and col_offset < tensor_row_major.dimension(1):
                expected_row_major = tensor_row_major(b, col_offset, row_offset, d)
              if twod_patch_row_major(b, patchId, c, r, d) != expected_row_major:
                print("Mismatch detected at index i=", i, " j=", j, " r=", r, " c=", c, " d=", d, " b=", b)
              VERIFY_IS_EQUAL(twod_patch_row_major(b, patchId, c, r, d), expected_row_major)
              VERIFY_IS_EQUAL(expected, expected_row_major)

def test_patch_padding_valid() raises:
  var input_depth: Int = 3
  var input_rows: Int = 3
  var input_cols: Int = 3
  var input_batches: Int = 1
  var ksize: Int = 2
  var stride: Int = 2

  var tensor = Tensor[Float32, 4](input_depth, input_rows, input_cols, input_batches)
  for i in range(tensor.size()):
    tensor.data()[i] = Float32(i + 1)

  var result = tensor.extract_image_patches(ksize, ksize, stride, stride, 1, 1, PADDING_VALID)
  VERIFY_IS_EQUAL(result.dimension(0), input_depth)
  VERIFY_IS_EQUAL(result.dimension(1), ksize)
  VERIFY_IS_EQUAL(result.dimension(2), ksize)
  VERIFY_IS_EQUAL(result.dimension(3), 1)
  VERIFY_IS_EQUAL(result.dimension(4), input_batches)

  var tensor_row_major = Tensor[Float32, 4, RowMajor](tensor.swap_layout())
  VERIFY_IS_EQUAL(tensor.dimension(0), tensor_row_major.dimension(3))
  VERIFY_IS_EQUAL(tensor.dimension(1), tensor_row_major.dimension(2))
  VERIFY_IS_EQUAL(tensor.dimension(2), tensor_row_major.dimension(1))
  VERIFY_IS_EQUAL(tensor.dimension(3), tensor_row_major.dimension(0))

  var result_row_major = tensor_row_major.extract_image_patches(ksize, ksize, stride, stride, 1, 1, PADDING_VALID)
  VERIFY_IS_EQUAL(result.dimension(0), result_row_major.dimension(4))
  VERIFY_IS_EQUAL(result.dimension(1), result_row_major.dimension(3))
  VERIFY_IS_EQUAL(result.dimension(2), result_row_major.dimension(2))
  VERIFY_IS_EQUAL(result.dimension(3), result_row_major.dimension(1))
  VERIFY_IS_EQUAL(result.dimension(4), result_row_major.dimension(0))

  var row_padding: Int = 0
  var col_padding: Int = 0
  var i: Int = 0
  while (i + stride + ksize - 1) < input_rows:
    var j: Int = 0
    while (j + stride + ksize - 1) < input_cols:
      var patchId = i + input_rows * j
      for r in range(ksize):
        for c in range(ksize):
          for d in range(input_depth):
            for b in range(input_batches):
              var expected = 0.0
              var expected_row_major = 0.0
              var row_offset = r + i - row_padding
              var col_offset = c + j - col_padding
              if row_offset >= 0 and col_offset >= 0 and row_offset < input_rows and col_offset < input_cols:
                expected = tensor(d, row_offset, col_offset, b)
                expected_row_major = tensor_row_major(b, col_offset, row_offset, d)
              if result(d, r, c, patchId, b) != expected:
                print("Mismatch detected at index i=", i, " j=", j, " r=", r, " c=", c, " d=", d, " b=", b)
              VERIFY_IS_EQUAL(result(d, r, c, patchId, b), expected)
              if result_row_major(b, patchId, c, r, d) != expected_row_major:
                print("Mismatch detected at index i=", i, " j=", j, " r=", r, " c=", c, " d=", d, " b=", b)
              VERIFY_IS_EQUAL(result_row_major(b, patchId, c, r, d), expected_row_major)
              VERIFY_IS_EQUAL(expected, expected_row_major)
      j += stride
    i += stride

def test_patch_padding_valid_same_value() raises:
  var input_depth: Int = 1
  var input_rows: Int = 5
  var input_cols: Int = 5
  var input_batches: Int = 2
  var ksize: Int = 3
  var stride: Int = 2

  var tensor = Tensor[Float32, 4](input_depth, input_rows, input_cols, input_batches)
  tensor = tensor.constant(11.0)

  var result = tensor.extract_image_patches(ksize, ksize, stride, stride, 1, 1, PADDING_VALID)
  VERIFY_IS_EQUAL(result.dimension(0), input_depth)
  VERIFY_IS_EQUAL(result.dimension(1), ksize)
  VERIFY_IS_EQUAL(result.dimension(2), ksize)
  VERIFY_IS_EQUAL(result.dimension(3), 4)
  VERIFY_IS_EQUAL(result.dimension(4), input_batches)

  var tensor_row_major = Tensor[Float32, 4, RowMajor](tensor.swap_layout())
  VERIFY_IS_EQUAL(tensor.dimension(0), tensor_row_major.dimension(3))
  VERIFY_IS_EQUAL(tensor.dimension(1), tensor_row_major.dimension(2))
  VERIFY_IS_EQUAL(tensor.dimension(2), tensor_row_major.dimension(1))
  VERIFY_IS_EQUAL(tensor.dimension(3), tensor_row_major.dimension(0))

  var result_row_major = tensor_row_major.extract_image_patches(ksize, ksize, stride, stride, 1, 1, PADDING_VALID)
  VERIFY_IS_EQUAL(result.dimension(0), result_row_major.dimension(4))
  VERIFY_IS_EQUAL(result.dimension(1), result_row_major.dimension(3))
  VERIFY_IS_EQUAL(result.dimension(2), result_row_major.dimension(2))
  VERIFY_IS_EQUAL(result.dimension(3), result_row_major.dimension(1))
  VERIFY_IS_EQUAL(result.dimension(4), result_row_major.dimension(0))

  var row_padding: Int = 0
  var col_padding: Int = 0
  var i: Int = 0
  while (i + stride + ksize - 1) <= input_rows:
    var j: Int = 0
    while (j + stride + ksize - 1) <= input_cols:
      var patchId = i + input_rows * j
      for r in range(ksize):
        for c in range(ksize):
          for d in range(input_depth):
            for b in range(input_batches):
              var expected = 0.0
              var expected_row_major = 0.0
              var row_offset = r + i - row_padding
              var col_offset = c + j - col_padding
              if row_offset >= 0 and col_offset >= 0 and row_offset < input_rows and col_offset < input_cols:
                expected = tensor(d, row_offset, col_offset, b)
                expected_row_major = tensor_row_major(b, col_offset, row_offset, d)
              if result(d, r, c, patchId, b) != expected:
                print("Mismatch detected at index i=", i, " j=", j, " r=", r, " c=", c, " d=", d, " b=", b)
              VERIFY_IS_EQUAL(result(d, r, c, patchId, b), expected)
              if result_row_major(b, patchId, c, r, d) != expected_row_major:
                print("Mismatch detected at index i=", i, " j=", j, " r=", r, " c=", c, " d=", d, " b=", b)
              VERIFY_IS_EQUAL(result_row_major(b, patchId, c, r, d), expected_row_major)
              VERIFY_IS_EQUAL(expected, expected_row_major)
      j += stride
    i += stride

def test_patch_padding_same() raises:
  var input_depth: Int = 3
  var input_rows: Int = 4
  var input_cols: Int = 2
  var input_batches: Int = 1
  var ksize: Int = 2
  var stride: Int = 2

  var tensor = Tensor[Float32, 4](input_depth, input_rows, input_cols, input_batches)
  for i in range(tensor.size()):
    tensor.data()[i] = Float32(i + 1)

  var result = tensor.extract_image_patches(ksize, ksize, stride, stride, PADDING_SAME)
  VERIFY_IS_EQUAL(result.dimension(0), input_depth)
  VERIFY_IS_EQUAL(result.dimension(1), ksize)
  VERIFY_IS_EQUAL(result.dimension(2), ksize)
  VERIFY_IS_EQUAL(result.dimension(3), 2)
  VERIFY_IS_EQUAL(result.dimension(4), input_batches)

  var tensor_row_major = Tensor[Float32, 4, RowMajor](tensor.swap_layout())
  VERIFY_IS_EQUAL(tensor.dimension(0), tensor_row_major.dimension(3))
  VERIFY_IS_EQUAL(tensor.dimension(1), tensor_row_major.dimension(2))
  VERIFY_IS_EQUAL(tensor.dimension(2), tensor_row_major.dimension(1))
  VERIFY_IS_EQUAL(tensor.dimension(3), tensor_row_major.dimension(0))

  var result_row_major = tensor_row_major.extract_image_patches(ksize, ksize, stride, stride, PADDING_SAME)
  VERIFY_IS_EQUAL(result.dimension(0), result_row_major.dimension(4))
  VERIFY_IS_EQUAL(result.dimension(1), result_row_major.dimension(3))
  VERIFY_IS_EQUAL(result.dimension(2), result_row_major.dimension(2))
  VERIFY_IS_EQUAL(result.dimension(3), result_row_major.dimension(1))
  VERIFY_IS_EQUAL(result.dimension(4), result_row_major.dimension(0))

  var row_padding: Int = 0
  var col_padding: Int = 0
  var i: Int = 0
  while (i + stride + ksize - 1) <= input_rows:
    var j: Int = 0
    while (j + stride + ksize - 1) <= input_cols:
      var patchId = i + input_rows * j
      for r in range(ksize):
        for c in range(ksize):
          for d in range(input_depth):
            for b in range(input_batches):
              var expected = 0.0
              var expected_row_major = 0.0
              var row_offset = r * stride + i - row_padding
              var col_offset = c * stride + j - col_padding
              if row_offset >= 0 and col_offset >= 0 and row_offset < input_rows and col_offset < input_cols:
                expected = tensor(d, row_offset, col_offset, b)
                expected_row_major = tensor_row_major(b, col_offset, row_offset, d)
              if result(d, r, c, patchId, b) != expected:
                print("Mismatch detected at index i=", i, " j=", j, " r=", r, " c=", c, " d=", d, " b=", b)
              VERIFY_IS_EQUAL(result(d, r, c, patchId, b), expected)
              if result_row_major(b, patchId, c, r, d) != expected_row_major:
                print("Mismatch detected at index i=", i, " j=", j, " r=", r, " c=", c, " d=", d, " b=", b)
              VERIFY_IS_EQUAL(result_row_major(b, patchId, c, r, d), expected_row_major)
              VERIFY_IS_EQUAL(expected, expected_row_major)
      j += stride
    i += stride

def test_patch_no_extra_dim() raises:
  var tensor = Tensor[Float32, 3](2, 3, 5)
  tensor.setRandom()
  var tensor_row_major = Tensor[Float32, 3, RowMajor](tensor.swap_layout())
  VERIFY_IS_EQUAL(tensor.dimension(0), tensor_row_major.dimension(2))
  VERIFY_IS_EQUAL(tensor.dimension(1), tensor_row_major.dimension(1))
  VERIFY_IS_EQUAL(tensor.dimension(2), tensor_row_major.dimension(0))

  var single_pixel_patch = Tensor[Float32, 4]()
  single_pixel_patch = tensor.extract_image_patches(1, 1)
  VERIFY_IS_EQUAL(single_pixel_patch.dimension(0), 2)
  VERIFY_IS_EQUAL(single_pixel_patch.dimension(1), 1)
  VERIFY_IS_EQUAL(single_pixel_patch.dimension(2), 1)
  VERIFY_IS_EQUAL(single_pixel_patch.dimension(3), 3 * 5)

  var single_pixel_patch_row_major = Tensor[Float32, 4, RowMajor]()
  single_pixel_patch_row_major = tensor_row_major.extract_image_patches(1, 1)
  VERIFY_IS_EQUAL(single_pixel_patch_row_major.dimension(0), 3 * 5)
  VERIFY_IS_EQUAL(single_pixel_patch_row_major.dimension(1), 1)
  VERIFY_IS_EQUAL(single_pixel_patch_row_major.dimension(2), 1)
  VERIFY_IS_EQUAL(single_pixel_patch_row_major.dimension(3), 2)

  for i in range(tensor.size()):
    if tensor.data()[i] != single_pixel_patch.data()[i]:
      print("Mismatch detected at index ", i, " : ", tensor.data()[i], " vs ", single_pixel_patch.data()[i])
    VERIFY_IS_EQUAL(single_pixel_patch.data()[i], tensor.data()[i])
    if tensor_row_major.data()[i] != single_pixel_patch_row_major.data()[i]:
      print("Mismatch detected at index ", i, " : ", tensor.data()[i], " vs ", single_pixel_patch_row_major.data()[i])
    VERIFY_IS_EQUAL(single_pixel_patch_row_major.data()[i], tensor_row_major.data()[i])
    VERIFY_IS_EQUAL(tensor.data()[i], tensor_row_major.data()[i])
    VERIFY_IS_EQUAL(single_pixel_patch.data()[i], single_pixel_patch_row_major.data()[i])

  var entire_image_patch = Tensor[Float32, 4]()
  entire_image_patch = tensor.extract_image_patches(3, 5)
  VERIFY_IS_EQUAL(entire_image_patch.dimension(0), 2)
  VERIFY_IS_EQUAL(entire_image_patch.dimension(1), 3)
  VERIFY_IS_EQUAL(entire_image_patch.dimension(2), 5)
  VERIFY_IS_EQUAL(entire_image_patch.dimension(3), 3 * 5)

  var entire_image_patch_row_major = Tensor[Float32, 4, RowMajor]()
  entire_image_patch_row_major = tensor_row_major.extract_image_patches(3, 5)
  VERIFY_IS_EQUAL(entire_image_patch_row_major.dimension(0), 3 * 5)
  VERIFY_IS_EQUAL(entire_image_patch_row_major.dimension(1), 5)
  VERIFY_IS_EQUAL(entire_image_patch_row_major.dimension(2), 3)
  VERIFY_IS_EQUAL(entire_image_patch_row_major.dimension(3), 2)

  for i in range(3):
    for j in range(5):
      var patchId = i + 3 * j
      for r in range(3):
        for c in range(5):
          for d in range(2):
            var expected = 0.0
            var expected_row_major = 0.0
            if r - 1 + i >= 0 and c - 2 + j >= 0 and r - 1 + i < 3 and c - 2 + j < 5:
              expected = tensor(d, r - 1 + i, c - 2 + j)
              expected_row_major = tensor_row_major(c - 2 + j, r - 1 + i, d)
            if entire_image_patch(d, r, c, patchId) != expected:
              print("Mismatch detected at index i=", i, " j=", j, " r=", r, " c=", c, " d=", d)
            VERIFY_IS_EQUAL(entire_image_patch(d, r, c, patchId), expected)
            if entire_image_patch_row_major(patchId, c, r, d) != expected_row_major:
              print("Mismatch detected at index i=", i, " j=", j, " r=", r, " c=", c, " d=", d)
            VERIFY_IS_EQUAL(entire_image_patch_row_major(patchId, c, r, d), expected_row_major)
            VERIFY_IS_EQUAL(expected, expected_row_major)

  var twod_patch = Tensor[Float32, 4]()
  twod_patch = tensor.extract_image_patches(2, 2)
  VERIFY_IS_EQUAL(twod_patch.dimension(0), 2)
  VERIFY_IS_EQUAL(twod_patch.dimension(1), 2)
  VERIFY_IS_EQUAL(twod_patch.dimension(2), 2)
  VERIFY_IS_EQUAL(twod_patch.dimension(3), 3 * 5)

  var twod_patch_row_major = Tensor[Float32, 4, RowMajor]()
  twod_patch_row_major = tensor_row_major.extract_image_patches(2, 2)
  VERIFY_IS_EQUAL(twod_patch_row_major.dimension(0), 3 * 5)
  VERIFY_IS_EQUAL(twod_patch_row_major.dimension(1), 2)
  VERIFY_IS_EQUAL(twod_patch_row_major.dimension(2), 2)
  VERIFY_IS_EQUAL(twod_patch_row_major.dimension(3), 2)

  var row_padding: Int = 0
  var col_padding: Int = 0
  var stride: Int = 1
  for i in range(3):
    for j in range(5):
      var patchId = i + 3 * j
      for r in range(2):
        for c in range(2):
          for d in range(2):
            var expected = 0.0
            var expected_row_major = 0.0
            var row_offset = r * stride + i - row_padding
            var col_offset = c * stride + j - col_padding
            if row_offset >= 0 and col_offset >= 0 and row_offset < tensor.dimension(1) and col_offset < tensor.dimension(2):
              expected = tensor(d, row_offset, col_offset)
            if twod_patch(d, r, c, patchId) != expected:
              print("Mismatch detected at index i=", i, " j=", j, " r=", r, " c=", c, " d=", d)
            VERIFY_IS_EQUAL(twod_patch(d, r, c, patchId), expected)
            if row_offset >= 0 and col_offset >= 0 and row_offset < tensor_row_major.dimension(1) and col_offset < tensor_row_major.dimension(0):
              expected_row_major = tensor_row_major(col_offset, row_offset, d)
            if twod_patch_row_major(patchId, c, r, d) != expected_row_major:
              print("Mismatch detected at index i=", i, " j=", j, " r=", r, " c=", c, " d=", d)
            VERIFY_IS_EQUAL(twod_patch_row_major(patchId, c, r, d), expected_row_major)
            VERIFY_IS_EQUAL(expected, expected_row_major)

def test_imagenet_patches() raises:
  var l_in = Tensor[Float32, 4](3, 128, 128, 16)
  l_in.setRandom()
  var l_out = l_in.extract_image_patches(11, 11)
  VERIFY_IS_EQUAL(l_out.dimension(0), 3)
  VERIFY_IS_EQUAL(l_out.dimension(1), 11)
  VERIFY_IS_EQUAL(l_out.dimension(2), 11)
  VERIFY_IS_EQUAL(l_out.dimension(3), 128 * 128)
  VERIFY_IS_EQUAL(l_out.dimension(4), 16)

  var l_out_row_major = l_in.swap_layout().extract_image_patches(11, 11)
  VERIFY_IS_EQUAL(l_out_row_major.dimension(0), 16)
  VERIFY_IS_EQUAL(l_out_row_major.dimension(1), 128 * 128)
  VERIFY_IS_EQUAL(l_out_row_major.dimension(2), 11)
  VERIFY_IS_EQUAL(l_out_row_major.dimension(3), 11)
  VERIFY_IS_EQUAL(l_out_row_major.dimension(4), 3)

  for b in range(16):
    for i in range(128):
      for j in range(128):
        var patchId = i + 128 * j
        for c in range(11):
          for r in range(11):
            for d in range(3):
              var expected = 0.0
              if r - 5 + i >= 0 and c - 5 + j >= 0 and r - 5 + i < 128 and c - 5 + j < 128:
                expected = l_in(d, r - 5 + i, c - 5 + j, b)
              if l_out(d, r, c, patchId, b) != expected:
                print("Mismatch detected at index i=", i, " j=", j, " r=", r, " c=", c, " d=", d, " b=", b)
              VERIFY_IS_EQUAL(l_out(d, r, c, patchId, b), expected)
              if l_out_row_major(b, patchId, c, r, d) != expected:
                print("Mismatch detected at index i=", i, " j=", j, " r=", r, " c=", c, " d=", d, " b=", b)
              VERIFY_IS_EQUAL(l_out_row_major(b, patchId, c, r, d), expected)

  l_in.resize(16, 64, 64, 32)
  l_in.setRandom()
  l_out = l_in.extract_image_patches(9, 9)
  VERIFY_IS_EQUAL(l_out.dimension(0), 16)
  VERIFY_IS_EQUAL(l_out.dimension(1), 9)
  VERIFY_IS_EQUAL(l_out.dimension(2), 9)
  VERIFY_IS_EQUAL(l_out.dimension(3), 64 * 64)
  VERIFY_IS_EQUAL(l_out.dimension(4), 32)

  l_out_row_major = l_in.swap_layout().extract_image_patches(9, 9)
  VERIFY_IS_EQUAL(l_out_row_major.dimension(0), 32)
  VERIFY_IS_EQUAL(l_out_row_major.dimension(1), 64 * 64)
  VERIFY_IS_EQUAL(l_out_row_major.dimension(2), 9)
  VERIFY_IS_EQUAL(l_out_row_major.dimension(3), 9)
  VERIFY_IS_EQUAL(l_out_row_major.dimension(4), 16)

  for b in range(32):
    for i in range(64):
      for j in range(64):
        var patchId = i + 64 * j
        for c in range(9):
          for r in range(9):
            for d in range(16):
              var expected = 0.0
              if r - 4 + i >= 0 and c - 4 + j >= 0 and r - 4 + i < 64 and c - 4 + j < 64:
                expected = l_in(d, r - 4 + i, c - 4 + j, b)
              if l_out(d, r, c, patchId, b) != expected:
                print("Mismatch detected at index i=", i, " j=", j, " r=", r, " c=", c, " d=", d, " b=", b)
              VERIFY_IS_EQUAL(l_out(d, r, c, patchId, b), expected)
              if l_out_row_major(b, patchId, c, r, d) != expected:
                print("Mismatch detected at index i=", i, " j=", j, " r=", r, " c=", c, " d=", d, " b=", b)
              VERIFY_IS_EQUAL(l_out_row_major(b, patchId, c, r, d), expected)

  l_in.resize(32, 16, 16, 32)
  l_in.setRandom()
  l_out = l_in.extract_image_patches(7, 7)
  VERIFY_IS_EQUAL(l_out.dimension(0), 32)
  VERIFY_IS_EQUAL(l_out.dimension(1), 7)
  VERIFY_IS_EQUAL(l_out.dimension(2), 7)
  VERIFY_IS_EQUAL(l_out.dimension(3), 16 * 16)
  VERIFY_IS_EQUAL(l_out.dimension(4), 32)

  l_out_row_major = l_in.swap_layout().extract_image_patches(7, 7)
  VERIFY_IS_EQUAL(l_out_row_major.dimension(0), 32)
  VERIFY_IS_EQUAL(l_out_row_major.dimension(1), 16 * 16)
  VERIFY_IS_EQUAL(l_out_row_major.dimension(2), 7)
  VERIFY_IS_EQUAL(l_out_row_major.dimension(3), 7)
  VERIFY_IS_EQUAL(l_out_row_major.dimension(4), 32)

  for b in range(32):
    for i in range(16):
      for j in range(16):
        var patchId = i + 16 * j
        for c in range(7):
          for r in range(7):
            for d in range(32):
              var expected = 0.0
              if r - 3 + i >= 0 and c - 3 + j >= 0 and r - 3 + i < 16 and c - 3 + j < 16:
                expected = l_in(d, r - 3 + i, c - 3 + j, b)
              if l_out(d, r, c, patchId, b) != expected:
                print("Mismatch detected at index i=", i, " j=", j, " r=", r, " c=", c, " d=", d, " b=", b)
              VERIFY_IS_EQUAL(l_out(d, r, c, patchId, b), expected)
              if l_out_row_major(b, patchId, c, r, d) != expected:
                print("Mismatch detected at index i=", i, " j=", j, " r=", r, " c=", c, " d=", d, " b=", b)
              VERIFY_IS_EQUAL(l_out_row_major(b, patchId, c, r, d), expected)

  l_in.resize(64, 13, 13, 32)
  l_in.setRandom()
  l_out = l_in.extract_image_patches(3, 3)
  VERIFY_IS_EQUAL(l_out.dimension(0), 64)
  VERIFY_IS_EQUAL(l_out.dimension(1), 3)
  VERIFY_IS_EQUAL(l_out.dimension(2), 3)
  VERIFY_IS_EQUAL(l_out.dimension(3), 13 * 13)
  VERIFY_IS_EQUAL(l_out.dimension(4), 32)

  l_out_row_major = l_in.swap_layout().extract_image_patches(3, 3)
  VERIFY_IS_EQUAL(l_out_row_major.dimension(0), 32)
  VERIFY_IS_EQUAL(l_out_row_major.dimension(1), 13 * 13)
  VERIFY_IS_EQUAL(l_out_row_major.dimension(2), 3)
  VERIFY_IS_EQUAL(l_out_row_major.dimension(3), 3)
  VERIFY_IS_EQUAL(l_out_row_major.dimension(4), 64)

  for b in range(32):
    for i in range(13):
      for j in range(13):
        var patchId = i + 13 * j
        for c in range(3):
          for r in range(3):
            for d in range(64):
              var expected = 0.0
              if r - 1 + i >= 0 and c - 1 + j >= 0 and r - 1 + i < 13 and c - 1 + j < 13:
                expected = l_in(d, r - 1 + i, c - 1 + j, b)
              if l_out(d, r, c, patchId, b) != expected:
                print("Mismatch detected at index i=", i, " j=", j, " r=", r, " c=", c, " d=", d, " b=", b)
              VERIFY_IS_EQUAL(l_out(d, r, c, patchId, b), expected)
              if l_out_row_major(b, patchId, c, r, d) != expected:
                print("Mismatch detected at index i=", i, " j=", j, " r=", r, " c=", c, " d=", d, " b=", b)
              VERIFY_IS_EQUAL(l_out_row_major(b, patchId, c, r, d), expected)

def test_cxx11_tensor_image_patch() raises:
  CALL_SUBTEST_1(test_simple_patch())
  CALL_SUBTEST_2(test_patch_no_extra_dim())
  CALL_SUBTEST_3(test_patch_padding_valid())
  CALL_SUBTEST_4(test_patch_padding_valid_same_value())
  CALL_SUBTEST_5(test_patch_padding_same())
  CALL_SUBTEST_6(test_imagenet_patches())
<<<FILE>>>