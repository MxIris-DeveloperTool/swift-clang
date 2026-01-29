// C++ features test file

namespace myns {
  class MyClass {
  public:
    void method() &;
    void method2() &&;
    int value;
  };
}

template<typename T>
class Container {
  T item;
};

// Template specialization
Container<int> intContainer;
