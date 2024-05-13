package com.example.demo


class HelloWorldController {
    fun helloWorld():String{
        return "Hello World"
    }
    fun fizzbuzz(i:Int):String{
        return when {
            i % 15 == 0->{"FizzBuzz"}
            i % 3 == 0->{"FizzBuzz"}
            i % 5 == 0->{"FizzBuzz"}
            else -> "$i"
        }
    }
}