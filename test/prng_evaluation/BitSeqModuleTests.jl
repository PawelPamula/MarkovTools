 module BitSeqUtilsTests
 
 export runBitSeqUtilsTests
 
 using Base.Test
 using BitSeqUtils
 
 
 function testCountOnes1()
    @test countOnes(Array(Bool, 0)) == 0
    @test countOnes(zeros(Bool, 1000)) == 0
    @test countOnes(ones(Bool, 1000)) == 1000
    @test countOnes(bool([1,0,1,1,0,0,1,1,0,0])) == 5
 end
 
 function testCountOnes2()
    checkPoints = [2,6,10]
    @test countOnes(bool([1,0,1,1,0,0,1,1,0,0]), checkPoints) == [1, 3, 5]
    checkPoints = [10, 100, 1000]
    @test countOnes(ones(Bool, 1000), checkPoints) == checkPoints
    @test countOnes(zeros(Bool, 1000), checkPoints) == [0,0,0]
 end
 
 function testCountOnes()
    testCountOnes1()
    testCountOnes2()
 end
 
 
 function testStringToBitArray()
    bits = [true, false, false, true, true, false]
    @test stringToBitArray("100110") == bits
    @test stringToBitArray("500.g0") == bits
    @test stringToBitArray("100110   \n   ") == bits
    @test stringToBitArray("   ") == []
 end
 
 
 
 
 
 
 
 
 
 
 
 
 
 function runBitSeqUtilsTests()
    testCountOnes()
    testStringToBitArray()
    println("All tests passed :)")
 end
 
 runBitSeqUtilsTests()
 
 end #module
 