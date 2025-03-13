from django.shortcuts import render
from django.http import HttpResponse

def index(request):
    return HttpResponse("vanakkam  from MyWorld App! - developed by jaikar devops engineer")

# Create your views here.
