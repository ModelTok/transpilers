class PrivateCode:
    # public:
    # FRIEND_TEST(PrivateCodeTest, CanAccessPrivateMembers)
    # FRIEND_TEST(PrivateCodeFixtureTest, CanAccessPrivateMembers)
    def __init__(self):
        self.x_ = 0
    def x(self) -> Int:
        return self.x_
    # private:
    def set_x(self, an_x: Int) -> None:
        self.x_ = an_x
    var x_: Int