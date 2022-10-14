<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <meta name="description" content="">
    <meta name="author" content="">
    <title>gpuview</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" 
        integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous"/>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css" 
        rel="stylesheet" type="text/css"/>
    <link href="https://cdn.datatables.net/1.10.16/css/dataTables.bootstrap4.min.css" rel="stylesheet"/>
    <link rel="shortcut icon" href="/static/img/vga-card.png" type="image/x-icon" />
</head>

<body class="fixed-nav sticky-footer bg-dark" id="page-top">
    <nav class="navbar navbar-expand-lg navbar-dark bg-dark fixed-top" id="mainNav">
        <img src="/static/img/vga-card.png" width="32" height="32" style="padding: 4px 4px 4px 4px">
        <a class="navbar-brand" href="">gpuview dashboard</a>
        <button class="navbar-toggler navbar-toggler-right" type="button" data-toggle="collapse" 
            data-target="#navbarResponsive"
            aria-controls="navbarResponsive" aria-expanded="false" aria-label="Toggle navigation">
            <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="navbarResponsive">
            <ul class="navbar-nav navbar-sidenav" id="exampleAccordion">
                <li class="nav-item" data-toggle="tooltip" data-placement="right" title="Table">
                    <!-- a class="nav-link" href="#table">
                        <i class="fas fa-table"></i>
                        <span class="nav-link-text">Table</span>
                    </a -->
                </li>
            </ul>
        </div>
        <input type="text" id="timeValue" value="0" style="color: red; font-size: 45px; border: none; background: transparent; outline: none; width: 200px; text-align: center;" readonly>
    </nav>
    <div class="content-wrapper" id="gpu-content">
        <div class="container-fluid" style="padding: 100px 40px 40px 40px">
            <form onsubmit="return handleData()" method="get" action="host_display" style="display: flex" id="hosts_form">
            % for host in hosts:
            <div style="margin-right:8px">
            <input type="checkbox" id={{host['name']}} name={{host['name']}} {{'checked' if host['display'] else ''}} class="hosts_form" onclick="user_refresh()">
            <label for={{host['name']}} style="color:white"> {{host['name']}} </label><br>
            </div>
            % end
            <div>
            <input type="submit" name="submit" value="save"/>
            </div>
            </form>
            <div class="row">
                % for gpustat in gpustats:
                % for gpu in gpustat.get('gpus', []):
                <div class="col-xl-3 col-md-4 col-sm-6 mb-3" style="display:block">
                    <div class="card text-white {{ gpu.get('flag', '') }} o-hidden h-100">
                        <div class="card-body">
                            <div class="float-left">
                                <div class="card-body-icon">
                                    <i class="fa fa-server"></i> <b>{{ gpustat.get('hostname', '-') }}</b>
                                </div>
                                <div>[{{ gpu.get('index', '') }}] {{ gpu.get('name', '-') }}</div>
                            </div>
                        </div>
                        <div class="card-footer text-white clearfix small z-1">
                            <span class="float-left">
                                <span class="text-nowrap">
                                <i class="fa fa-thermometer-three-quarters" aria-hidden="true"></i>
                                Temp. {{ gpu.get('temperature.gpu', '-') }}&#8451; 
                                </span> |
                                <span class="text-nowrap">
                                <i class="fa fa-microchip" aria-hidden="true"></i>
                                Mem. {{ gpu.get('memory', '-') }}% 
                                </span> |
                                <span class="text-nowrap">
                                <i class="fa fa-cogs" aria-hidden="true"></i>
                                Util. {{ gpu.get('utilization.gpu', '-') }}%
                                </span> |
                                <span class="text-nowrap">
                                <i class="fa fa-users" aria-hidden="true"></i>
                                {{ gpu.get('users', '-') }}
                                </span>
                            </span>
                        </div>
                    </div>
                </div>
                % end
                % end
            </div>
            <!-- GPU Stat Card-->
            <div class="card mb-3">
                <div class="card-header">
                    <i class="fa fa-table"></i> All Hosts and GPUs</div>
                <div class="card-body">
                    <div class="table-responsive">
                        <table class="table table-bordered" id="dataTable" width="100%" cellspacing="0">
                            <thead>
                                <tr>
                                    <th scope="col">Host</th>
                                    <th scope="col">GPU</th>
                                    <th scope="col">Temp.</th>
                                    <th scope="col">Util.</th>
                                    <th scope="col">Memory Use/Cap</th>
                                    <th scope="col">Power Use/Cap</th>
                                    <th scope="col">User Processes</th>
                                </tr>
                            </thead>
                            <tbody>
                                % for gpustat in gpustats:
                                % for gpu in gpustat.get('gpus', []):
                                <tr class="small" id={{ gpustat.get('hostname', '-') }}>
                                    <th scope="row">{{ gpustat.get('hostname', '-') }} </th>
                                    <td> [{{ gpu.get('index', '') }}] {{ gpu.get('name', '-') }} </td>
                                    <td> {{ gpu.get('temperature.gpu', '-') }}&#8451; </td>
                                    <td> {{ gpu.get('utilization.gpu', '-') }}% </td>
                                    <td> {{ gpu.get('memory', '-') }}% ({{ gpu.get('memory.used', '') }}/{{ gpu.get('memory.total', '-') }}) </td>
                                    <td> {{ gpu.get('power.draw', '-') }} / {{ gpu.get('enforced.power.limit', '-') }} </td>
                                    <td> {{ gpu.get('user_processes', '-') }} </td>
                                </tr>
                                % end
                                % end
                            </tbody>
                        </table>
                    </div>
                </div>
                <div class="card-footer small text-muted">{{ update_time }}</div>
            </div>
            <footer class="sticky-footer">
                <div class="container">
                    <div class="text-center text-white">
                        <small><a href='https://github.com/fgaim/gpuview'>gpuview</a> © 2022</small>
                    </div>
                </div>
            </footer>
        </div>
    </div>
    <script src="https://code.jquery.com/jquery-3.3.1.min.js" 
        integrity="sha256-FgpCb/KJQlLNfOu91ta32o/NMZxltwRo8QtmkMRdAu8="
        crossorigin="anonymous"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/js/bootstrap.min.js" 
        integrity="sha384-JZR6Spejh4U02d8jOt6vLEHfe/JQGiRRSQQxSfFWpi1MquVdAyjUar5+76PVCmYl"
        crossorigin="anonymous"></script>
    <script src="https://cdn.datatables.net/1.10.16/js/jquery.dataTables.min.js"></script>
    <script src="https://cdn.datatables.net/1.10.16/js/dataTables.bootstrap4.min.js"></script>
    <script>
    var auto_clock;
    let is_user_refresh = false;

    $(function(){
        auto_clock = setInterval(refresh, 5000);
    })

    function refresh(){
        if (!is_user_refresh){
            table = document.getElementById("hosts_form");
            cells = table.getElementsByClassName('hosts_form');
            let postfix = ""
            for (let i = 0; i < cells.length; i++) {
                if (cells[i].checked){
                    postfix += cells[i].name + "=on&"
                }
            }
            $.ajax({url:"/content?"+postfix+"submit=none",success:function(result){
                if (!is_user_refresh){
                    resetTimer();
                    $("#gpu-content").html(result);
                } else {
                    is_user_refresh = false;
                }
            }});
        } else {
            is_user_refresh = false;
        }
    }

    function user_refresh(){
        is_user_refresh = true;
        table = document.getElementById("hosts_form");
        cells = table.getElementsByClassName('hosts_form');
        let postfix = ""
        for (let i = 0; i < cells.length; i++) {
            if (cells[i].checked){
                postfix += cells[i].name + "=on&"
            }
        }
        $.ajax({url:"/content?"+postfix+"submit=none",success:function(result){
            resetTimer();
            $("#gpu-content").html(result);
            is_user_refresh = false;
        }});
    }

    var second;
    second=0;
    setInterval(function(){
        second++;
        document.getElementById('timeValue').value=second;
    },1000);

    function resetTimer()
    {
        second=0;
        document.getElementById('timeValue').value=second;
    }

    function handleData()
    {
        resetTimer()
    }
    </script>
</body>

</html>
