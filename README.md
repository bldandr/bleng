# Bleng

> Интерпретатор, написанный на Free Pascal в образовательных целях.

## Возможности 

1. Циклы(for и while)
2. Локальные и глобальные переменные базовых типов(целочисленный, вещественный, строковый, символьный, флаговый, массивы)
3. Оператор ветвления (if/else)
4. Подпрограммы(процедуры)

## Сборка и запуск

```Shell
fpc main.pas
./main
```

## Пример программы на Bleng(сортировка массива QuickSort):
```c++
[10]integer a;

func quicksort(integer low, high) {
  integer i, j, pivot, temp;
   
  if low < high then {
    pivot = a[(low + high) // 2];
    i = low;
    j = high;

    while i <= j do {
      while a[i] < pivot do {i = i + 1;};
      while a[j] > pivot do {j = j - 1;};

      if i <= j then {
        temp = a[i];
        a[i] = a[j];
        a[j] = temp;
        i = i + 1;
        j = j - 1;
      }
    };

    if low < j then {quicksort(low, j);};
    if i < high then {quicksort(i, high);};
  }
}


func main {
  integer i;

  for i = 1 to 10 do {
    write("Введите "); write(i); write("-тый элемент: ");
    read(a[i]);
  };

  quicksort(1, 10);

  for i = 1 to 10 do {
    write(a[i]); write(" ");
  }
};
```
