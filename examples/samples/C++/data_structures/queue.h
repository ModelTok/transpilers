
#ifndef MEHARA_QUEUE_H_
#define MEHARA_QUEUE_H_

namespace mehara {

template <class T>
class queue {
  public:
    virtual void enqueue(T element) = 0;

    virtual T dequeue() = 0;

    virtual bool empty() = 0;

    virtual int size() = 0;

    virtual ~queue() {}
};

}

#endif
