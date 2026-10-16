
#ifndef MEHARA_LINKED_STACK_H_
#define MEHARA_LINKED_STACK_H_

#include "stack.h"

#include <stdexcept>

namespace mehara {

template <class T>
class linked_stack : public stack<T> {
  public:
    linked_stack();

    void push(T element) override;

    T pop() override;

    bool empty() override;

    int size() override;

    ~linked_stack() override;

  private:
    struct node {
        T element;
        node* next;
    };

    node* top_;
    int size_;
};

template <class T>
linked_stack<T>::linked_stack()
{
    top_ = nullptr;
    size_ = 0;
}

template <class T>
void linked_stack<T>::push(T element)
{
    node* current = new node();
    current->element = element;
    current->next = top_;
    top_ = current;
    size_++;
}

template <class T>
T linked_stack<T>::pop()
{
    if (size_ == 0) {
        throw std::underflow_error("Stack is already empty.");
    }
    node* current = top_;
    top_ = top_->next;
    T element = current->element;
    delete current;
    size_--;
    return element;
}

template <class T>
bool linked_stack<T>::empty()
{
    return size_ == 0;
}

template <class T>
int linked_stack<T>::size()
{
    return size_;
}

template <class T>
linked_stack<T>::~linked_stack()
{
    while (top_) {
        node* current = top_;
        top_ = top_->next;
        delete current;
        size_--;
    }
}

}

#endif
