
#ifndef MEHARA_STACK_H_
#define MEHARA_STACK_H_

namespace mehara {

template <class T>
class stack {
  public:
    virtual void push(T element) = 0;

    virtual T pop() = 0;

    virtual bool empty() = 0;

    virtual int size() = 0;

    virtual ~stack() {}
};

}

#endif
