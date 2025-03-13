from django.shortcuts import render
from django.http import HttpResponse

def index(request):
    return HttpResponse("namaste from  HelloWorld App! developed by jaikar ")

# Create your views here.
