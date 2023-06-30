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
        integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous" />
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css" rel="stylesheet"
        type="text/css" />
    <link href="https://cdn.datatables.net/1.10.16/css/dataTables.bootstrap4.min.css" rel="stylesheet" /
        type="text/css">
    <link href="/static/css/my.css" rel="stylesheet" type="text/css">
    <link rel="shortcut icon" href="/static/img/vga-card.png" type="image/x-icon" />
</head>

<body class="fixed-nav sticky-footer bg-dark" id="page-top">
    <nav class="navbar navbar-expand-lg navbar-dark bg-dark fixed-top" id="mainNav" style="padding-top:40px">
        <img src="/static/img/vga-card.png" width="32" height="32" style="margin-left: 20px;margin-right: 10px;">
        <a class="navbar-brand" href="">gpuview dashboard</a>
        <div style="margin-top:20px">
            <div class="wrapper" style="padding-left:20px">
                <label style="color:white;margin-right:12px"> Load: </label>
                <div class="box bg-primary"></div> <label style="color:white"> Empty </label>
                <div class="box bg-success"></div> <label style="color:white"> Low </label>
                <div class="box bg-warning"></div> <label style="color:white"> Middle </label>
                <div class="box bg-danger"></div> <label style="color:white"> High </label>
            </div>
            <form onsubmit="return handleData()" method="get" action="host_display" id="hosts_form"
                style="display: flex; padding-left:20px">
                <label style="color:white; margin-right:10px"> Server: </label>
                % for host in hosts:
                <div style="margin-right:8px">
                    <input type="checkbox" id={{host['name']}} name={{host['name']}} {{'checked' if host['display']
                        else '' }} class="hosts_form" onclick="user_refresh()">
                    <label for={{host['name']}} style="color:white"> {{host['name']}} </label><br>
                </div>
                % end
                <div style="color:white">
                    <a class="button button-blue" id="save_button">
                        <strong>Save</strong>
                    </a>
                </div>
                <script>
                    document.getElementById("save_button").onclick = function () {
                        document.getElementById("hosts_form").submit();
                    };
                </script>
            </form>
        </div>
    </nav>
    <div id="loader" style="display:none"></div>
    <input type="text" id="timeValue" value="0"
        style="display:none; color: red; font-size: 45px; border: none; background: transparent; outline: none; width: 200px; text-align: center;"
        readonly>
    %include('content.tpl')
    <script src="https://code.jquery.com/jquery-3.3.1.min.js"
        integrity="sha256-FgpCb/KJQlLNfOu91ta32o/NMZxltwRo8QtmkMRdAu8=" crossorigin="anonymous"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/js/bootstrap.min.js"
        integrity="sha384-JZR6Spejh4U02d8jOt6vLEHfe/JQGiRRSQQxSfFWpi1MquVdAyjUar5+76PVCmYl"
        crossorigin="anonymous"></script>
    <script src="https://cdn.datatables.net/1.10.16/js/jquery.dataTables.min.js"></script>
    <script src="https://cdn.datatables.net/1.10.16/js/dataTables.bootstrap4.min.js"></script>
    <script>
        var auto_clock;
        var is_checkbox_change;
        auto_clock = setInterval(refresh, 5000);
        is_checkbox_change = false;

        function refresh() {
            table = document.getElementById("hosts_form");
            cells = table.getElementsByClassName('hosts_form');
            let postfix = "";
            for (let i = 0; i < cells.length; i++) {
                if (cells[i].checked) {
                    postfix += cells[i].name + "=on&";
                }
            }
            $.ajax({
                url: "/content?" + postfix + "submit=none",
                success: function (result) {
                    if (is_checkbox_change) {
                        is_checkbox_change = false;
                        refresh();
                    } else {
                        resetTimer();
                        $("#gpu-content").html(result);
                    }
                    document.getElementById('loader').setAttribute("style", "display:none");
                },
                error: function (result) {
                    is_checkbox_change = false;
                    document.getElementById('loader').setAttribute("style", "display:grid");
                }
            });
        }

        function user_refresh() {
            table = document.getElementById("hosts_form");
            cells = table.getElementsByClassName('hosts_form');
            for (let i = 0; i < cells.length; i++) {
                blocks = document.getElementsByClassName("card-block " + cells[i].name);
                for (let j = 0; j < blocks.length; j++) {
                    if (cells[i].checked) {
                        blocks[j].setAttribute("style", "display:grid");
                    } else {
                        blocks[j].setAttribute("style", "display:none");
                    }
                }
            }
            is_checkbox_change = true;
        }

        var second;
        second = 0;
        setInterval(function () {
            second++;
            document.getElementById('timeValue').value = second;
        }, 1000);

        function resetTimer() {
            second = 0;
            document.getElementById('timeValue').value = second;
        }

        function handleData() {
            resetTimer();
        }
    </script>
</body>

</html>
