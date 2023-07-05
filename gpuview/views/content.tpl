<div class="content-wrapper" id="gpu-content">
    <div class="container-fluid" style="padding: 200px 40px 40px 40px">
        <!-- GPU status card -->
        <div class="row">
            % for gpustat in gpustats:
            % for gpu in gpustat.get('gpus', []):
            % include('block.tpl')
            % end
            % end
        </div>

        <!-- List of GPU process -->
        <div class="card mb-3">
            <div class="card-header">
                <i class="fa fa-table"></i> All Hosts and GPUs
            </div>
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
                            <tr class="small" id={{ gpustat.get('hostname', '-' ) }}>
                                <th scope="row">{{ gpustat.get('hostname', '-') }} </th>
                                <td> [{{ gpu.get('index', '') }}] {{ gpu.get('name', '-') }} </td>
                                <td> {{ gpu.get('temperature.gpu', '-') }}&#8451; </td>
                                <td> {{ gpu.get('utilization.gpu', '-') }}% </td>
                                <td> {{ gpu.get('memory', '-') }}%
                                    ({{ gpu.get('memory.used', '') }}/{{ gpu.get('memory.total', '-') }}) </td>
                                <td> {{ gpu.get('power.draw', '-') }} / {{ gpu.get('enforced.power.limit', '-') }} W
                                </td>
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
    </div>
</div>

<!-- 予約モーダル -->
<div id="reservationModal" class="modal">
    <div class="modal-content">
        <span class="close">&times;</span>
        <h2>Make a Reservation</h2>
        <form id="reservationForm" action="/reserve" method="post">
            <label for="username">Username:</label>
            <input type="text" name="username" id="username" required><br><br>
            <label for="usagetime">Usage Time:</label>
            <input type="number" name="usagetime" id="usagetime" required value="24">hours<br><br>
            <input type="hidden" name="gpuId" id="gpuId">
            <input type="submit" value="Submit">
        </form>
    </div>
</div>

<!-- キャンセルモーダル -->
<div id="cancelModal" class="modal">
    <div class="modal-content">
        <span class="close">&times;</span>
        <h2>Cancel Reservation</h2>
        <p id="reservationInfo"></p>
        <form id="cancelForm" action="/cancel" method="post">
            <input type="hidden" name="gpuId" id="gpuId">
            <input type="submit" value="Submit">
        </form>
    </div>
</div>

<script>
    // 予約ボタンとモーダルの要素を取得
    const reservationModal = document.getElementById("reservationModal");
    const reservationForm = document.getElementById("reservationForm");
    const cancelModal = document.getElementById("cancelModal");
    const cancelForm = document.getElementById("cancelForm");
    const reservationInfo = document.getElementById("reservationInfo");

    function openModal(element) {
        console.log(element.id);
        // クリックしたカードのGPU IDをformに埋め込む
        if (element.classList.contains("bg-primary")) {
            // 予約する時
            reservationModal.style.display = "block";
            const gpuIdInputEl = reservationModal.querySelector("#gpuId");
            gpuIdInputEl.setAttribute("value", element.id);
        } else if (element.classList.contains("bg-danger")) {
            // キャンセルする時
            cancelModal.style.display = "block";
            const gpuIdInputEl = cancelModal.querySelector("#gpuId");
            gpuIdInputEl.setAttribute("value", element.id);
        }
    }

    // // 予約モーダル内のフォームの送信イベントリスナー
    // reservationForm.addEventListener("submit", function (event) {
    //     event.preventDefault(); // フォームのデフォルトの送信をキャンセル
    //     // フォームの入力値を取得
    //     const username = reservationForm.querySelector("#username").value;
    //     const usagetime = reservationForm.querySelector("#usagetime").value;
    //     const gpuId = reservationForm.querySelector("#gpuId").value;
    //     // 選択したカードを取得
    //     const gpuCard = document.getElementById(gpuId);
    //     // モーダルを閉じる
    //     reservationModal.style.display = "none";
    //     // フォームをリセット
    //     reservationForm.reset();
    //     // TODO:DBからDBから取ってくるようにして後で消す
    //     // 予約ボタンをキャンセルボタンに変更
    //     gpuCard.classList.remove("bg-primary");
    //     gpuCard.classList.add("bg-danger");
    //     // 予約情報の表示
    //     reservationInfo.textContent = "Username: " + username + ", Usage Time: " + usagetime;
    //     // 改めてsubmit
    //     reservationForm.submit();
    // });

    // // キャンセルモーダルのフォームの送信イベントリスナー
    // cancelForm.addEventListener("submit", function (event) {
    //     // event.preventDefault(); // フォームのデフォルトの送信をキャンセル
    //     // フォームの入力値を取得
    //     const gpuId = reservationForm.querySelector("#gpuId").value;
    //     // 選択したカードを取得
    //     const gpuCard = document.getElementById(gpuId);
    //     // モーダルを閉じる
    //     cancelModal.style.display = "none";
    //     // TODO:DBからDBから取ってくるようにして後で消す
    //     // 予約ボタンを予約モードに変更
    //     gpuCard.classList.remove("bg-danger");
    //     gpuCard.classList.add("bg-primary");
    //     // 予約情報をリセット
    //     reservationInfo.textContent = "";
    //     // 改めてsubmit
    //     reservationForm.submit();
    // });

    // Close Reservation Modal
    reservationModal.querySelector(".close").addEventListener("click", () => {
        reservationModal.style.display = "none";
    });
    // Close Cancel Modal
    cancelModal.querySelector(".close").addEventListener("click", () => {
        cancelModal.style.display = "none";
    });
    // モーダル外をクリックしてモーダルを閉じる
    window.addEventListener("click", (event) => {
        if (event.target == reservationModal) {
            reservationModal.style.display = "none";
        } else if (event.target == cancelModal) {
            cancelModal.style.display = "none";
        }
    });
</script>
