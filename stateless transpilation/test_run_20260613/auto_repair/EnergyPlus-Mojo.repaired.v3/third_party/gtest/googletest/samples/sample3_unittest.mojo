from sample3-inl import Queue, QueueNode
from gtest import TEST_F, EXPECT_EQ, ASSERT_TRUE, ASSERT_EQ

struct QueueTestSmpl3:
    var q0_: Queue[Int]
    var q1_: Queue[Int]
    var q2_: Queue[Int]

    def SetUp(self):
        self.q1_.Enqueue(1)
        self.q2_.Enqueue(2)
        self.q2_.Enqueue(3)

    @staticmethod
    def Double(n: Int) -> Int:
        return 2 * n

    def MapTester(self, q: Queue[Int]):
        var new_q = q.Map(QueueTestSmpl3.Double)
        ASSERT_EQ(q.Size(), new_q.Size())
        var n1 = q.Head()
        var n2 = new_q.Head()
        while n1:
            EXPECT_EQ(2 * n1.element(), n2.element())
            n1 = n1.next()
            n2 = n2.next()
        del new_q

TEST_F[QueueTestSmpl3]("DefaultConstructor", fn(self: QueueTestSmpl3):
    EXPECT_EQ(0, self.q0_.Size())
)

TEST_F[QueueTestSmpl3]("Dequeue", fn(self: QueueTestSmpl3):
    var n = self.q0_.Dequeue()
    EXPECT_TRUE(n == None)
    n = self.q1_.Dequeue()
    ASSERT_TRUE(n != None)
    EXPECT_EQ(1, n[])
    EXPECT_EQ(0, self.q1_.Size())
    del n
    n = self.q2_.Dequeue()
    ASSERT_TRUE(n != None)
    EXPECT_EQ(2, n[])
    EXPECT_EQ(1, self.q2_.Size())
    del n
)

TEST_F[QueueTestSmpl3]("Map", fn(self: QueueTestSmpl3):
    self.MapTester(self.q0_)
    self.MapTester(self.q1_)
    self.MapTester(self.q2_)
)