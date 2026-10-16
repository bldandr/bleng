[20]int a;

func quicksort(int low, high) {
  int i, j, pivot, temp;
   
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
  int i;

  for i = 1 to 9 do {
    write("Введите "); write(i); write("-тый элемент: ");
    read(a[i]);
  };

  quicksort(1, 9);

  for i = 1 to 9 do {
    write(a[i]); write(" ");
  }
};